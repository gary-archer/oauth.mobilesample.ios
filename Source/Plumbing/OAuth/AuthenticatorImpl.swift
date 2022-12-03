// swiftlint:disable file_length
// swiftlint:disable type_body_length

import AppAuth

/*
 * The class for handling OAuth operations
 */
class AuthenticatorImpl: Authenticator {

    private let configuration: OAuthConfiguration
    private var metadata: OIDServiceConfiguration?
    private var currentOAuthSession: OIDExternalUserAgentSession?
    private var tokenStorage: TokenStorage
    private var loginResponseHandler: LoginResponseHandler
    private var logoutResponseHandler: LogoutResponseHandler
    private let concurrencyHandler: ConcurrentActionHandler

    /*
     * Initialise from input
     */
    init (configuration: OAuthConfiguration) {
        self.configuration = configuration
        self.tokenStorage = TokenStorage()
        self.loginResponseHandler = LoginResponseHandler()
        self.logoutResponseHandler = LogoutResponseHandler()
        self.concurrencyHandler = ConcurrentActionHandler()
    }

    /*
     * Download OpenID Connect metadata and return it to the caller
     */
    func getMetadata() async throws {

        // Do nothing if already loaded
        if self.metadata != nil {
            return
        }

        // Get the metadata endpoint as a URL object
        guard let issuerUrl = URL(string: self.configuration.authority) else {
            let message = "Unable to create URL from \(self.configuration.authority)"
            throw ErrorFactory.fromMessage(message: message)
        }

        return try await withCheckedThrowingContinuation { continuation in

            // Try to download metadata
            OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { metadata, error in

                self.metadata = metadata
                if error != nil {
                    continuation.resume(throwing: error!)
                }

                continuation.resume()
            }
        }
    }

    /*
     * Try to get an access token, which most commonly involves returning the current one
     */
    func getAccessToken() async throws -> String {

        let accessToken = self.tokenStorage.loadTokens()?.accessToken
        if accessToken != nil {

            // Use the token from storage if possible
            return accessToken!

        } else {

            // Otherwise try to use the refresh token to get a new access token
            let refreshedAccessToken = try await self.refreshAccessToken()
            return refreshedAccessToken
        }
    }

    /*
     * Try to refresh an access token
     */
    func refreshAccessToken() async throws -> String {

        let refreshToken = self.tokenStorage.loadTokens()?.refreshToken

        // Execute the refresh token grant message and manage concurrency
        if refreshToken != nil {
            try await self.concurrencyHandler.execute(action: self.performRefreshTokenGrant)
        }

        // Reload and see if we now have a new access token
        let accessToken = self.tokenStorage.loadTokens()?.accessToken
        if accessToken != nil {

            // Return the new access token if the refresh succeeded
            return accessToken!

        } else {

            // Otherwise indicate a login is required
            throw ErrorFactory.fromLoginRequired()
        }
    }

    /*
     * The OAuth entry point for login processing runs on the UI thread
     */
    func startLoginRedirect(viewController: UIViewController) throws {

        do {

            // Get the redirect address into a URL object
            let redirectUri = self.getLoginRedirectUri()
            guard let loginRedirectUri = URL(string: redirectUri) else {
                let message = "Error creating URL for : \(redirectUri)"
                throw ErrorFactory.fromMessage(message: message)
            }

            // Set additional parameters such as acr_values if applicable
            let additionalParameters = [String: String]()

            // Build the authorization request
            let scopesArray = self.configuration.scope.components(separatedBy: " ")
            let request = OIDAuthorizationRequest(
                configuration: self.metadata!,
                clientId: self.configuration.clientId,
                clientSecret: nil,
                scopes: scopesArray,
                redirectURL: loginRedirectUri,
                responseType: OIDResponseTypeCode,
                additionalParameters: additionalParameters)

            // Do the redirect
            self.currentOAuthSession = OIDAuthorizationService.present(
                request,
                presenting: viewController,
                callback: self.loginResponseHandler.callback)

        } catch {

            // Handle errors
            self.currentOAuthSession = nil
            throw ErrorFactory.fromLoginRequestError(error: error)
        }
    }

    /*
     * Complete login processing on a background thread
     */
    func handleLoginResponse() async throws -> OIDAuthorizationResponse {

        do {

            self.currentOAuthSession = nil
            return try await self.loginResponseHandler.waitForCallback()

        } catch {

            if self.isCancelledError(error: error) {
                throw ErrorFactory.fromRedirectCancelled()
            }

            throw ErrorFactory.fromLoginResponseError(error: error)
        }
    }

    /*
     * The authorization code grant runs on a background thread
     */
    func finishLogin(authResponse: OIDAuthorizationResponse) async throws {

        self.currentOAuthSession = nil
        let request = authResponse.tokenExchangeRequest()

        return try await withCheckedThrowingContinuation { continuation in

            // Make the authorization code grant request
            OIDAuthorizationService.perform(
                request!,
                originalAuthorizationResponse: authResponse) { tokenResponse, error in

                    if error != nil {

                        // Throw errors
                        let uiError = ErrorFactory.fromTokenError(
                            error: error!,
                            errorCode: ErrorCodes.authorizationCodeGrantFailed)
                        continuation.resume(throwing: uiError)
                    }

                    // Save the tokens to storage
                    self.saveTokens(tokenResponse: tokenResponse!)
                    continuation.resume()
                }
        }
    }

    /*
     * The OAuth entry point for logout processing
     */
    func startLogoutRedirect(viewController: UIViewController) throws {

        // Do nothing if already logged out
        let tokenData = self.tokenStorage.loadTokens()
        if tokenData == nil || tokenData!.idToken == nil {
            return
        }

        do {

            // Clear tokens
            let idToken = tokenData!.idToken!
            self.tokenStorage.removeTokens()

            // Get the post logout address as a URL object
            let postLogoutUrl = self.getPostLogoutRedirectUri()
            guard let postLogoutRedirectUri = URL(string: postLogoutUrl) else {
                let message = "Error creating URL for : \(postLogoutUrl)"
                throw ErrorFactory.fromMessage(message: message)
            }

            // Create an object to manage provider differences
            let logoutManager = self.createLogoutManager()

            // If required, create an updated metadata object with an end session endpoint
            let metadataWithEndSessionEndpoint = try logoutManager.updateMetadata(
                metadata: self.metadata!)

            // Build the end session request
            let request = logoutManager.createEndSessionRequest(
                metadata: metadataWithEndSessionEndpoint,
                idToken: idToken,
                postLogoutRedirectUri: postLogoutRedirectUri)

            // Do the logout redirect
            let agent = OIDExternalUserAgentIOS(presenting: viewController)
            self.currentOAuthSession = OIDAuthorizationService.present(
                request,
                externalUserAgent: agent!,
                callback: self.logoutResponseHandler.callback)

        } catch {

            // Handle errors
            self.currentOAuthSession = nil
            throw ErrorFactory.fromLogoutRequestError(error: error)
        }
    }

    /*
     * Process the logout response and free resources
     */
    func handleLogoutResponse() async throws -> OIDEndSessionResponse {

        do {

            self.currentOAuthSession = nil
            return try await self.logoutResponseHandler.waitForCallback()

        } catch {

            // If the user cancels the logout we throw a special error
            if self.isCancelledError(error: error) {
                throw ErrorFactory.fromRedirectCancelled()
            }

            // Report other errors
            throw ErrorFactory.fromLogoutRequestError(error: error)
        }
    }

    /*
     * Return true if the URL matches an OAuth response reactivation URL from the interstitial page
     */
    func isOAuthResponse(responseUrl: URL) -> Bool {

        return
            responseUrl.absoluteString.lowercased().starts(with: self.getLoginReactivateUri().lowercased()) ||
            responseUrl.absoluteString.lowercased().starts(with: self.getPostLogoutReactivateUri().lowercased())
    }

    /*
     * Resume a login or logout operation
     * We need to work around this AppAuth iOS issue: https://github.com/openid/AppAuth-iOS/issues/356
     * To do so we must resume on the original redirect URI so some string replacement is needed
     */
    func resumeOperation(responseUrl: URL) {

        if self.currentOAuthSession != nil {

            var resumeUrl: String?
            let queryString = responseUrl.query ?? ""

            // If we are invoked on the login activation URL then resume on the login redirect URI
            let loginActivationUri = self.getLoginReactivateUri().lowercased()
            let loginRedirectUri = self.getLoginRedirectUri().lowercased()
            if responseUrl.absoluteString.lowercased().starts(with: loginActivationUri) {
                resumeUrl = "\(loginRedirectUri)?\(queryString)"
            }

            // If we are invoked on the logout activation URL then resume on the logout redirect URI
            let logoutActivationUri = self.getPostLogoutReactivateUri().lowercased()
            let logoutRedirectUri = self.getPostLogoutRedirectUri().lowercased()
            if responseUrl.absoluteString.lowercased().starts(with: logoutActivationUri) {
                resumeUrl = "\(logoutRedirectUri)?\(queryString)"
            }

            // Resume OAuth processing with the URL
            if resumeUrl != nil {
                self.currentOAuthSession!.resumeExternalUserAgentFlow(
                    with: URL(string: resumeUrl!)!)
            }
        }
    }

    /*
     * A hacky method for testing, to update token storage to make the access token act like it is expired
     */
    func expireAccessToken() {
        self.tokenStorage.expireAccessToken()
    }

    /*
    * A hacky method for testing, to update token storage to make the refresh token act like it is expired
    */
    func expireRefreshToken() {
        self.tokenStorage.expireRefreshToken()
    }

    /*
     * A synchronised method to do the work of the refresh token grant
     */
    private func performRefreshTokenGrant() async throws {

        let tokenData = self.tokenStorage.loadTokens()

        // First get metadata if required
        try await self.getMetadata()

        // Create the refresh token grant request
        let request = OIDTokenRequest(
            configuration: self.metadata!,
            grantType: OIDGrantTypeRefreshToken,
            authorizationCode: nil,
            redirectURL: nil,
            clientID: self.configuration.clientId,
            clientSecret: nil,
            scope: nil,
            refreshToken: tokenData!.refreshToken!,
            codeVerifier: nil,
            additionalParameters: nil)

        return try await withCheckedThrowingContinuation { continuation in

            OIDAuthorizationService.perform(request) { tokenResponse, error in

                // Handle errors
                if error != nil {

                    if self.matchesAppAuthError(
                        error: error!,
                        domain: OIDOAuthTokenErrorDomain,
                        code: OIDErrorCodeOAuth.invalidGrant.rawValue) {

                        // If we get an invalid_grant error it means the refresh token has expired
                        // In this case clear tokens and return, which will trigger a login redirect
                        self.tokenStorage.removeTokens()
                        continuation.resume()
                        return
                    }

                    // Handle other errors
                    let uiError = ErrorFactory.fromTokenError(
                        error: error!,
                        errorCode: ErrorCodes.refreshTokenGrantFailed)
                    continuation.resume(throwing: uiError)
                    return
                }

                // Make a sanity check to ensure we have tokens
                if tokenResponse == nil || tokenResponse!.accessToken == nil {
                    let message = "No tokens were received in the Refresh Token Grant message"
                    continuation.resume(throwing: ErrorFactory.fromMessage(message: message))
                    return
                }

                // Save received tokens and return success
                self.saveTokens(tokenResponse: tokenResponse!)
                continuation.resume()
            }
        }
    }

    /*
     * Save tokens from an authoprization code grant or refresh token grant response
     */
    private func saveTokens(tokenResponse: OIDTokenResponse) {

        // Create token data from the response
        let newTokenData = TokenData()
        newTokenData.accessToken = tokenResponse.accessToken!
        if tokenResponse.refreshToken != nil {
            newTokenData.refreshToken = tokenResponse.refreshToken!
        }
        if tokenResponse.idToken != nil {
            newTokenData.idToken = tokenResponse.idToken!
        }

        // Handle missing tokens in the token response
        let oldTokenData = self.tokenStorage.loadTokens()
        if oldTokenData != nil {

            // Maintain the existing refresh token unless we received a new 'rolling' refresh token
            if newTokenData.refreshToken == nil {
                newTokenData.refreshToken = oldTokenData!.refreshToken
            }

            // Maintain the existing id token if required, which may be needed for logout
            if newTokenData.idToken == nil {
                newTokenData.idToken = oldTokenData!.idToken
            }
        }

        // Update storage
        self.tokenStorage.saveTokens(newTokenData: newTokenData)
    }

    /*
     * Detect a user cancellation error, which we want to treat specially
     * The below Github issue returns the same code and domain, so we distinguish via a string comparison
     * https://github.com/openid/AppAuth-iOS/issues/498
     */
    private func isCancelledError(error: Error) -> Bool {

        let authError = error as NSError
        let startupError = "The UIWindowScene for the returned window was not in the foreground active state"
        return self.matchesAppAuthError(
            error: error,
            domain: OIDGeneralErrorDomain,
            code: OIDErrorCode.userCanceledAuthorizationFlow.rawValue) &&
            !authError.userInfo.description.localizedStandardContains(startupError)
    }

    /*
     * Check for a particular AppAuth error
     */
    private func matchesAppAuthError(error: Error, domain: String, code: Int) -> Bool {
        let authError = error as NSError
        return authError.domain == domain && authError.code == code
    }

    /*
     * Return the URL to the interstitial page used for login redirects
     * https://authsamples.com/apps/basicmobileapp/postlogin.html
     */
    private func getLoginRedirectUri() -> String {
        return "\(self.configuration.webBaseUrl)\(self.configuration.loginRedirectPath)"
    }

    /*
     * Return the URL to the interstitial page used for logout redirects
     * https://authsamples.com/apps/basicmobileapp/postlogout.html
     */
    private func getPostLogoutRedirectUri() -> String {
        return "\(self.configuration.webBaseUrl)\(self.configuration.postLogoutRedirectPath)"
    }

    /*
     * Return the deep linking app location that the interstitial page invokes after login
     * https://mobile.authsamples.com/basicmobileapp/oauth/callback
     */
    private func getLoginReactivateUri() -> String {
        return "\(self.configuration.deepLinkBaseUrl)\(self.configuration.loginActivatePath)"
    }

    /*
     * Return the deep linking app location that the interstitial page invokes after logout
     * https://mobile.authsamples.com/basicmobileapp/oauth/logoutcallback
     */
    private func getPostLogoutReactivateUri() -> String {
        return "\(self.configuration.deepLinkBaseUrl)\(self.configuration.postLogoutActivatePath)"
    }

    /*
     * Return the logout manager for the active provider
     */
    private func createLogoutManager() -> LogoutManager {

        if self.configuration.authority.lowercased().contains("cognito") {
            return CognitoLogoutManager(configuration: self.configuration)
        } else {
            return StandardLogoutManager(configuration: self.configuration)
        }
    }
}
