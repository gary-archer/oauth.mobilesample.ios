// swiftlint:disable file_length
import AppAuth

/*
 * The class for handling OAuth operations
 */
// swiftlint:disable type_body_length
class OAuthClientImpl: OAuthClient {

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
     * One time initialization on application startup
     */
    func initialize() async throws {

        // Load OpenID Connect metadata
        try await getMetadata()

        // Load tokens from storage
        self.tokenStorage.loadTokens()
    }

    /*
     * Download OpenID Connect metadata and return it to the caller
     */
    private func getMetadata() async throws {

        // Do nothing if already loaded
        if self.metadata != nil {
            return
        }

        // Get the metadata endpoint as a URL object
        guard let issuerUrl = URL(string: self.configuration.authority) else {
            let message = "Unable to create URL from \(self.configuration.authority)"
            throw ErrorFactory.fromMessage(message: message)
        }

        // Try to download metadata
        return try await withCheckedThrowingContinuation { continuation in

            OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { metadata, error in

                if error != nil {

                    // Report errors
                    continuation.resume(throwing: ErrorFactory.fromMetadataLookupError(error: error!))

                } else {

                    // Indicate success
                    self.metadata = metadata
                    continuation.resume()
                }
            }
        }
    }

    /*
     * Try to get an access token, which most commonly involves returning the current one
     */
    func getAccessToken() -> String? {
        return self.tokenStorage.getTokens()?.accessToken
    }

    /*
     * Try to refresh an access token
     */
    func synchronizedRefreshAccessToken() async throws -> String {

        let refreshToken = self.tokenStorage.getTokens()?.refreshToken

        // Execute the refresh token grant message and manage concurrency
        if refreshToken != nil {
            try await self.concurrencyHandler.execute(action: self.performRefreshTokenGrant)
        }

        // Reload and see if we now have a new access token
        let accessToken = self.tokenStorage.getTokens()?.accessToken
        if accessToken != nil {

            // Return the new access token if the refresh succeeded
            return accessToken!

        } else {

            // Otherwise indicate a login is required
            throw ErrorFactory.fromLoginRequired()
        }
    }

    /*
     * Return the logged in status
     */
    func isLoggedIn() -> Bool {
        return self.tokenStorage.getTokens() != nil
    }

    /*
     * The OAuth entry point for login processing runs on the UI thread
     */
    func startLoginRedirect(viewController: UIViewController) throws {

        do {

            // Get the redirect address into a URL object
            guard let loginRedirectUri = URL(string: self.configuration.redirectUri) else {
                let message = "Error creating URL for : \(self.configuration.redirectUri)"
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

            return try await self.loginResponseHandler.waitForCallback()

        } catch {

            self.currentOAuthSession = nil

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
        let tokenData = self.tokenStorage.getTokens()
        if tokenData == nil || tokenData!.idToken == nil {
            return
        }

        do {

            // Clear tokens
            let idToken = tokenData!.idToken!
            self.clearLoginState()

            // Get the post logout address as a URL object
            guard let postLogoutRedirectUri = URL(string: self.configuration.postLogoutRedirectUri) else {
                let message = "Error creating URL for : \(self.configuration.postLogoutRedirectUri)"
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
    func handleLogoutResponse() async throws -> OIDEndSessionResponse? {

        do {

            return try await self.logoutResponseHandler.waitForCallback()

        } catch {

            self.currentOAuthSession = nil

            // If the user cancels the logout we throw a special error
            if self.isCancelledError(error: error) {
                throw ErrorFactory.fromRedirectCancelled()
            }

            // Treat logout state mismatch errors as benign
            if self.isLogoutStateMismatchError(error: error) {
                return nil
            }

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
     * We need to work around this AppAuth iOS bug: https://github.com/openid/AppAuth-iOS/issues/356
     * The request used a redirect URI beginning with https://www.authsamples.com
     * The response URL begins with https://mobile.authsamples.com and the library does not accept it
     * To resolvet this we must do some string replacement to update the response URL
     */
    func resumeOperation(responseUrl: URL) {

        if self.currentOAuthSession != nil {

            var resumeUrl: String?
            let queryString = responseUrl.query ?? ""

            // If we are invoked on the login activation URL then resume on the login redirect URI
            let loginActivationUri = self.getLoginReactivateUri().lowercased()
            if responseUrl.absoluteString.lowercased().starts(with: loginActivationUri) {
                resumeUrl = "\(self.configuration.redirectUri)?\(queryString)"
            }

            // If we are invoked on the logout activation URL then resume on the logout redirect URI
            let logoutActivationUri = self.getPostLogoutReactivateUri().lowercased()
            if responseUrl.absoluteString.lowercased().starts(with: logoutActivationUri) {
                resumeUrl = "\(self.configuration.postLogoutRedirectUri)?\(queryString)"
            }

            // Resume OAuth processing with the URL
            if resumeUrl != nil {
                self.currentOAuthSession!.resumeExternalUserAgentFlow(with: URL(string: resumeUrl!)!)
            } else {
                self.currentOAuthSession!.resumeExternalUserAgentFlow(with: responseUrl)
            }
        }
    }

    /*
     * Allow the login state to be cleared when required
     */
    func clearLoginState() {
        self.tokenStorage.removeTokens()
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

        let tokenData = self.tokenStorage.getTokens()

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
                        self.clearLoginState()
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
        let oldTokenData = self.tokenStorage.getTokens()
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
     * Return true if this is a user cancellation error that can be ignored and not the value from the below issue
     * https://github.com/openid/AppAuth-iOS/issues/498
     */
    private func isCancelledError(error: Error) -> Bool {

        let authError = error as NSError
        return self.matchesAppAuthError(
            error: error,
            domain: OIDGeneralErrorDomain,
            code: OIDErrorCode.userCanceledAuthorizationFlow.rawValue) &&
            !authError.userInfo.description.localizedStandardContains("active state")
    }

    /*
     * Return true if this is a logout state mismatch error that is expected and can be ignored
     */
    private func isLogoutStateMismatchError(error: Error) -> Bool {

        let authError = error as NSError
        return self.matchesAppAuthError(
            error: error,
            domain: OIDOAuthAuthorizationErrorDomain,
            code: OIDErrorCodeOAuth.clientError.rawValue) &&
            authError.userInfo.description.localizedStandardContains("State mismatch")
    }

    /*
     * Check for a particular AppAuth error
     */
    private func matchesAppAuthError(error: Error, domain: String, code: Int) -> Bool {
        let authError = error as NSError
        return authError.domain == domain && authError.code == code
    }

    /*
     * Return the deep linking app location that the interstitial page invokes after login
     */
    private func getLoginReactivateUri() -> String {
        return "\(self.configuration.deepLinkBaseUrl)/finalmobileapp/oauth/callback"
    }

    /*
     * Return the deep linking app location that the interstitial page invokes after logout
     */
    private func getPostLogoutReactivateUri() -> String {
        return "\(self.configuration.deepLinkBaseUrl)/finalmobileapp/oauth/logoutcallback"
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
// swiftlint:enable type_body_length
