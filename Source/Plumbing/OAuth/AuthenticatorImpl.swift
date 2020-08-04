// swiftlint:disable file_length
// swiftlint:disable type_body_length

import AppAuth
import SwiftCoroutine

/*
 * The class for handling OAuth operations
 */
class AuthenticatorImpl: Authenticator {

    private let configuration: OAuthConfiguration
    private var metadata: OIDServiceConfiguration?
    private var currentOAuthSession: OIDExternalUserAgentSession?
    private var tokenStorage: TokenStorage
    private let concurrencyHandler: ConcurrentActionHandler

    /*
     * Initialise from input
     */
    init (configuration: OAuthConfiguration) {
        self.configuration = configuration
        self.tokenStorage = TokenStorage()
        self.concurrencyHandler = ConcurrentActionHandler()
    }

    /*
     * We are logged in if there are tokens
     */
    func isLoggedIn() -> Bool {
        return self.tokenStorage.loadTokens() != nil
    }

    /*
     * Try to get an access token, which most commonly involves returning the current one
     */
    func getAccessToken() -> CoFuture<String> {

        let promise = CoPromise<String>()

        do {
            let accessToken = self.tokenStorage.loadTokens()?.accessToken
            if accessToken != nil {

                // Use the token from storage if possible
                promise.success(accessToken!)

            } else {

                // Otherwise try to use the refresh token to get a new access token
                let refreshedAccessToken = try self.refreshAccessToken().await()
                promise.success(refreshedAccessToken)
            }
        } catch {
            promise.fail(error)
        }

        return promise
    }

    /*
     * Try to refresh an access token
     */
    func refreshAccessToken() -> CoFuture<String> {

        let promise = CoPromise<String>()
        let refreshToken = self.tokenStorage.loadTokens()?.refreshToken

        do {

            // Execute the refresh token grant message and manage concurrency
            if refreshToken != nil {
                try self.concurrencyHandler.execute(action: self.performRefreshTokenGrant).await()
            }

            // Reload and see if we now have a new access token
            let accessToken = self.tokenStorage.loadTokens()?.accessToken
            if accessToken != nil {

                // Return the new access token if the refresh succeeded
                promise.success(accessToken!)

            } else {

                // Otherwise indicate a login is required
                promise.fail(ErrorHandler.fromLoginRequired())
            }
        } catch {

            // Rethrow downstream errors
            promise.fail(error)
        }

        return promise
    }

    /*
     * The OAuth entry point for login processing runs on the UI thread
     */
    func startLogin(
        viewController: UIViewController) -> CoFuture<OIDAuthorizationResponse> {

        let promise = CoPromise<OIDAuthorizationResponse>()

        do {
            // Trigger the login redirect and get the authorization code
            let response = try self.performLoginRedirect(viewController: viewController)
                .await()

            // Indicate success
            promise.success(response)

        } catch {

            // Handle errors
            self.currentOAuthSession = nil
            let uiError = ErrorHandler.fromLoginRequestError(error: error)
            promise.fail(uiError)
        }

        return promise
    }

    /*
     * The authorization code grant runs on a background thread
     */
    func finishLogin(authResponse: OIDAuthorizationResponse) -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        do {

            // Next swap the authorization code for tokens
            try self.exchangeAuthorizationCode(authResponse: authResponse)
                .await()

            // Indicate success and clean up
            promise.success(Void())

        } catch {

            // Handle errors
            let uiError = ErrorHandler.fromLoginResponseError(error: error)
            promise.fail(uiError)
        }

        self.currentOAuthSession = nil
        return promise
    }

    /*
     * The OAuth entry point for logout processing
     */
    func logout(viewController: UIViewController) -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        // Do nothing if already logged out
        let tokenData = self.tokenStorage.loadTokens()
        if tokenData == nil || tokenData!.idToken == nil {
            promise.success(Void())
        }

        do {

            // Clear tokens
            let idToken = tokenData!.idToken!
            self.tokenStorage.removeTokens()

            // Do the work of the logout redirect
            try self.performLogoutRedirect(viewController: viewController, idToken: idToken)
                .await()

            // Indicate success
            promise.success(Void())

        } catch {

            // Handle errors
            let uiError = ErrorHandler.fromLogoutRequestError(error: error)
            promise.fail(uiError)
        }

        self.currentOAuthSession = nil
        return promise
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
     * Download Open Id Connect metadata and return it to the caller
     */
    private func getMetadata() -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        // Do nothing if already loaded
        if self.metadata != nil {
            promise.success(Void())
            return promise
        }

        // Get the metadata endpoint as a URL object
        guard let issuerUrl = URL(string: self.configuration.authority) else {
            let message = "Unable to create URL from \(self.configuration.authority)"
            promise.fail(ErrorHandler.fromMessage(message: message))
            return promise
        }

        // Try to download metadata
        OIDAuthorizationService.discoverConfiguration(
            forIssuer: issuerUrl) { metadata, error in

                self.metadata = metadata
                if error != nil {
                    promise.fail(ErrorHandler.fromException(error: error!))
                } else {
                    promise.success(Void())
                }
        }

        return promise
    }

    /*
     * Do the work of the login redirect and return the authorization code
     */
    private func performLoginRedirect
        (viewController: UIViewController) throws -> CoFuture<OIDAuthorizationResponse> {

        let promise = CoPromise<OIDAuthorizationResponse>()

        // First get metadata if required
        try self.getMetadata().await()

        // Get the redirect address into a URL object
        let redirectUri = self.getLoginRedirectUri()
        guard let loginRedirectUri = URL(string: redirectUri) else {
            let message = "Error creating URL for : \(redirectUri)"
            promise.fail(ErrorHandler.fromMessage(message: message))
            return promise
        }

        // Build the authorization request
        let scopesArray = self.configuration.scope.components(separatedBy: " ")
        let request = OIDAuthorizationRequest(
            configuration: self.metadata!,
            clientId: self.configuration.clientId,
            clientSecret: nil,
            scopes: scopesArray,
            redirectURL: loginRedirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        // Do the redirect
        self.currentOAuthSession =
            OIDAuthorizationService.present(request, presenting: viewController) { response, error in

                // Handle errors
                if error != nil {

                    // If the user cancels the login we throw a special error
                    if self.matchesAppAuthError(
                        error: error!,
                        domain: OIDGeneralErrorDomain,
                        code: OIDErrorCode.userCanceledAuthorizationFlow.rawValue) {

                        promise.fail(ErrorHandler.fromRedirectCancelled())
                        return
                    }

                    // Handle other errors
                    let uiError = ErrorHandler.fromLoginResponseError(error: error!)
                    promise.fail(uiError)
                    return
                }

                // Make a sanity check to ensure we have a response
                if response == nil || response!.authorizationCode == nil {
                    let message = "No authorization code was received after a successful login redirect"
                    promise.fail(ErrorHandler.fromMessage(message: message))
                    return
                }

                // On success, return the authorization response to the caller
                promise.success(response!)
            }

        return promise
    }

    /*
     * Swap the authorization code for tokens
     */
    private func exchangeAuthorizationCode(authResponse: OIDAuthorizationResponse) -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        // Make the authorization code grant request
        let request = authResponse.tokenExchangeRequest()
        OIDAuthorizationService.perform(
            request!,
            originalAuthorizationResponse: authResponse) { tokenResponse, error in

            // Handle errors
            if error != nil {
                let uiError = ErrorHandler.fromTokenError(
                    error: error!,
                    errorCode: ErrorCodes.authorizationCodeGrantFailed)
                promise.fail(uiError)
                return
            }

            // Save the tokens to storage
            self.saveTokens(tokenResponse: tokenResponse!)

            // Update tokens and indicate success
            promise.success(Void())
        }

        return promise
    }

    /*
     * A synchronised method to do the work of the refresh token grant
     */
    private func performRefreshTokenGrant() -> CoFuture<Void> {

        let promise = CoPromise<Void>()
        let tokenData = self.tokenStorage.loadTokens()

        do {
            // First get metadata if required
            try self.getMetadata().await()

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

            // Trigger the request
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
                        promise.success(Void())
                        return
                    }

                    // Handle other errors
                    let uiError = ErrorHandler.fromTokenError(
                        error: error!,
                        errorCode: ErrorCodes.refreshTokenGrantFailed)
                    promise.fail(uiError)
                    return
                }

                // Make a sanity check to ensure we have tokens
                if tokenResponse == nil || tokenResponse!.accessToken == nil {
                    let message = "No tokens were received in the Refresh Token Grant message"
                    promise.fail(ErrorHandler.fromMessage(message: message))
                    return
                }

                // Save received tokens and return success
                self.saveTokens(tokenResponse: tokenResponse!)
                promise.success(Void())
            }
        } catch {

            // Handle errors
            promise.fail(ErrorHandler.fromException(error: error))
        }

        return promise
    }

    /*
     * Do the work of the logout redirect
     */
    private func performLogoutRedirect(
        viewController: UIViewController,
        idToken: String) throws -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        // First get metadata if required
        try self.getMetadata().await()

        // Get the post logout address as a URL object
        let postLogoutUrl = self.getPostLogoutRedirectUri()
        guard let postLogoutRedirectUri = URL(string: postLogoutUrl) else {
            let message = "Error creating URL for : \(postLogoutUrl)"
            promise.fail(ErrorHandler.fromMessage(message: message))
            return promise
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
        self.currentOAuthSession =
            OIDAuthorizationService.present(request, externalUserAgent: agent!) { _, error in

                // Handle errors
                if error != nil {

                    // If the user cancels the login we throw a special error
                    if self.matchesAppAuthError(
                        error: error!,
                        domain: OIDGeneralErrorDomain,
                        code: OIDErrorCode.userCanceledAuthorizationFlow.rawValue) {

                        promise.fail(ErrorHandler.fromRedirectCancelled())
                        return
                    }

                    // Ignore benign errors
                    if logoutManager.isExpectedError(error: error!) {
                        promise.success(Void())
                        return
                    }

                    // Report other errors
                    let uiError = ErrorHandler.fromLogoutRequestError(error: error!)
                    promise.fail(uiError)
                    return
                }

                // Indicate success
                promise.success(Void())
            }

        return promise
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
     * Check for a particular AppAuth error
     */
    private func matchesAppAuthError(error: Error, domain: String, code: Int) -> Bool {
        let authError = error as NSError
        return authError.domain == domain && authError.code == code
    }

    /*
     * Return the URL to the interstitial page used for login redirects
     * https://mobile.authsamples.com/html/basicmobileapp/postlogin.html
     */
    private func getLoginRedirectUri() -> String {
        return "\(self.configuration.mobileBaseUrl)\(self.configuration.loginRedirectPath)"
    }

    /*
     * Return the URL to the interstitial page used for logout redirects
     * https://mobile.authsamples.com/html/basicmobileapp/postlogout.html
     */
    private func getPostLogoutRedirectUri() -> String {
        return "\(self.configuration.mobileBaseUrl)\(self.configuration.postLogoutRedirectPath)"
    }

    /*
     * Return the deep linking app location that the interstitial page invokes after login
     * https://mobile.authsamples.com/basicmobileapp/oauth/callback
     */
    private func getLoginReactivateUri() -> String {
        return "\(self.configuration.mobileBaseUrl)\(self.configuration.loginActivatePath)"
    }

    /*
     * Return the deep linking app location that the interstitial page invokes after logout
     * https://mobile.authsamples.com/basicmobileapp/oauth/logoutcallback
     */
    private func getPostLogoutReactivateUri() -> String {
        return "\(self.configuration.mobileBaseUrl)\(self.configuration.postLogoutActivatePath)"
    }

    /*
     * Return the logout manager for the active provider
     */
    private func createLogoutManager() -> LogoutManager {

        if self.configuration.authority.lowercased().contains("cognito") {
            return CognitoLogoutManager(configuration: self.configuration)
        } else {
            return OktaLogoutManager(configuration: self.configuration)
        }
    }
}
