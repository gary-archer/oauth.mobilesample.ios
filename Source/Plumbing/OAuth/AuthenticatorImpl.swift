// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import AppAuth
import SwiftCoroutine
import SwiftKeychainWrapper

/*
 * The class for handling OAuth operations
 */
class AuthenticatorImpl: Authenticator {

    // Properties
    private let configuration: OAuthConfiguration
    private var currentOAuthSession: OIDExternalUserAgentSession?
    private var tokenData: TokenData?
    private let concurrencyHandler: ConcurrentActionHandler
    private let storageKey = "com.authguidance.basicmobileapp.tokendata"

    /*
     * Initialise from input
     */
    init (configuration: OAuthConfiguration) {

        self.configuration = configuration
        self.concurrencyHandler = ConcurrentActionHandler()

        // Try to populate token data from the keychain, so that the user does not need to login
        let jsonText = KeychainWrapper.standard.string(forKey: self.storageKey)
        if jsonText != nil {
            let data = jsonText!.data(using: .utf8)
            let decoder = JSONDecoder()
            self.tokenData = try? decoder.decode(TokenData.self, from: data!)
        }
    }

    /*
     * We are logged in if there are tokens
     */
    func isLoggedIn() -> Bool {
        return self.tokenData != nil
    }

    /*
     * Try to get an access token, which most commonly involves returning the current one
     */
    func getAccessToken() -> CoFuture<String> {

        let promise = CoPromise<String>()

        do {
            if self.tokenData != nil && self.tokenData!.accessToken != nil {

                // Use the token from storage if possible
                promise.success(self.tokenData!.accessToken!)

            } else {

                // Otherwise try to use the refresh token to get a new access token
                let token = try self.refreshAccessToken().await()
                promise.success(token)
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

        do {

            // Check that refresh is possible
            if self.tokenData != nil && self.tokenData!.refreshToken != nil {

                // Execute the refresh token grant message and manage concurrency
                try self.concurrencyHandler.execute(action: self.performRefreshTokenGrant).await()
            }

            if self.tokenData != nil && self.tokenData!.accessToken != nil {

                // Return the new access token if the refresh succeeded
                promise.success(self.tokenData!.accessToken!)

            } else {

                // Otherwise indicate a login is required
                promise.fail(ErrorHandler().fromLoginRequired())
            }
        } catch {

            // Rethrow downstream errors
            promise.fail(error)
        }

        return promise
    }

    /*
     * A hacky method for testing, to update token storage to make the access token act like it is expired
     */
    func expireAccessToken() {

        if self.tokenData != nil && self.tokenData!.accessToken != nil {
            self.tokenData!.accessToken = "x\(self.tokenData!.accessToken!)x"
        }
    }

    /*
    * A hacky method for testing, to update token storage to make the refresh token act like it is expired
    */
    func expireRefreshToken() {

        if self.tokenData != nil && self.tokenData!.refreshToken != nil {
            self.tokenData!.accessToken = nil
            self.tokenData!.refreshToken = "x\(self.tokenData!.refreshToken!)x"
        }
    }

    /*
     * The OAuth entry point for login processing
     */
    func login(viewController: UIViewController) -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        do {

            // First get metadata
            let metadata = try self.getMetadata()
                .await()

            // Next trigger the login redirect and get the authorization code
            let response = try self.performLoginRedirect(
                viewController: viewController,
                metadata: metadata)
                    .await()

            // Next swap the authorization code for tokens
            try DispatchQueue.global().await {
                try self.exchangeAuthorizationCode(authResponse: response)
                    .await()
            }

            // Indicate success
            self.currentOAuthSession = nil
            promise.success(Void())

        } catch {

            // Handle errors
            self.currentOAuthSession = nil
            promise.fail(ErrorHandler().fromException(error: error))
        }

        return promise
    }

    /*
     * The OAuth entry point for logout processing
     */
    func logout(viewController: UIViewController) -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        do {
            // Clear tokens from memory and storage
            let idToken = self.tokenData!.idToken!
            KeychainWrapper.standard.removeObject(forKey: self.storageKey)
            self.tokenData = nil

            // Get metadata
            let metadata = try self.getMetadata()
                .await()

            // Do the work of the logout redirect
            try self.performLogoutRedirect(
                viewController: viewController,
                metadata: metadata,
                idToken: idToken)
                    .await()

            // Indicate success
            self.currentOAuthSession = nil
            promise.success(Void())

        } catch {

            // Handle errors
            self.currentOAuthSession = nil
            promise.fail(ErrorHandler().fromException(error: error))
        }

        return promise
    }

    /*
     * Download Open Id Connect metadata and return it to the caller
     */
    private func getMetadata() -> CoFuture<OIDServiceConfiguration> {

        let promise = CoPromise<OIDServiceConfiguration>()

        // Get the metadata endpoint as a URL object
        guard let issuerUrl = URL(string: self.configuration.authority) else {
            let message = "Unable to create URL from \(self.configuration.authority)"
            promise.fail(ErrorHandler().fromMessage(message: message))
            return promise
        }

        // Try to download metadata
        OIDAuthorizationService.discoverConfiguration(
            forIssuer: issuerUrl) { metadata, error in

                if error != nil {
                    promise.fail(ErrorHandler().fromException(error: error!))
                } else {
                    promise.success(metadata!)
                }
        }

        return promise
    }

    /*
     * Do the work of the login redirect and return the authorization code
     */
    private func performLoginRedirect(
        viewController: UIViewController,
        metadata: OIDServiceConfiguration) -> CoFuture<OIDAuthorizationResponse> {

        let promise = CoPromise<OIDAuthorizationResponse>()

        // Get the redirect address into a URL object
        guard let redirectUri = URL(string: self.configuration.redirectUri) else {
            let message = "Error creating URL for : \(self.configuration.redirectUri)"
            promise.fail(ErrorHandler().fromMessage(message: message))
            return promise
        }

        // Build the authorization request
        let scopesArray = self.configuration.scope.components(separatedBy: " ")
        let request = OIDAuthorizationRequest(
            configuration: metadata,
            clientId: self.configuration.clientId,
            clientSecret: nil,
            scopes: scopesArray,
            redirectURL: redirectUri,
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

                        promise.fail(ErrorHandler().fromRedirectCancelled())
                        return
                    }

                    // Handle other errors
                    let uiError = ErrorHandler().fromAppAuthError(
                        error: error!,
                        errorCode: ErrorCodes.loginResponseFailed)
                    promise.fail(uiError)
                    return
                }

                // Make a sanity check to ensure we have a response
                if response == nil || response!.authorizationCode == nil {
                    let message = "No authorization code was received after a successful login redirect"
                    promise.fail(ErrorHandler().fromMessage(message: message))
                    return
                }

                // On success, return the authorization response to the caller
                promise.success(response!)
            }

        return promise
    }

    /*
     * Do the work of the logout redirect
     */
    private func performLogoutRedirect(
        viewController: UIViewController,
        metadata: OIDServiceConfiguration,
        idToken: String) -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        // Get the logout endpoint as a URL object
        guard let logoutUri = URL(string: self.configuration.logoutEndpoint) else {
            let message = "Error creating URL for : \(self.configuration.logoutEndpoint)"
            promise.fail(ErrorHandler().fromMessage(message: message))
            return promise
        }

        // Get the post logout address as a URL object
        guard let postLogoutRedirectUri = URL(string: self.configuration.postLogoutRedirectUri) else {
            let message = "Error creating URL for : \(self.configuration.postLogoutRedirectUri)"
            promise.fail(ErrorHandler().fromMessage(message: message))
            return promise
        }

        // Cognito has no end session endpoint and does not return one in its metadata
        // So create an updated metadata object with its vendor specific logout URL
        let metadataWithEndSessionEndpoint = OIDServiceConfiguration(
            authorizationEndpoint: metadata.authorizationEndpoint,
            tokenEndpoint: metadata.tokenEndpoint,
            issuer: metadata.issuer,
            registrationEndpoint: metadata.registrationEndpoint,
            endSessionEndpoint: logoutUri)

        // Build the logout request and include extra vendor specific parameters that Cognito requires
        let request = OIDEndSessionRequest(
            configuration: metadataWithEndSessionEndpoint,
            idTokenHint: idToken,
            postLogoutRedirectURL: postLogoutRedirectUri,
            state: "",
            additionalParameters: [
                "client_id": self.configuration.clientId,
                "logout_uri": self.configuration.postLogoutRedirectUri
            ])
        let agent = OIDExternalUserAgentIOS(presenting: viewController)

        // Do the logout redirect, and use the current authorization flow parameter
        self.currentOAuthSession =
            OIDAuthorizationService.present(request, externalUserAgent: agent!) { _, error in

                // Handle errors
                if error != nil {

                    // If the user cancels the login we throw a special error
                    if self.matchesAppAuthError(
                        error: error!,
                        domain: OIDGeneralErrorDomain,
                        code: OIDErrorCode.userCanceledAuthorizationFlow.rawValue) {

                        promise.fail(ErrorHandler().fromRedirectCancelled())
                        return
                    }

                    // Treat state mismatch errors as success, since Cognito does not return a state in the response
                    if error!.localizedDescription.lowercased().contains("state mismatch") {
                        promise.success(Void())
                        return
                    }

                    // Report other errors
                    let uiError = ErrorHandler().fromAppAuthError(
                        error: error!,
                        errorCode: ErrorCodes.logoutFailed)
                    promise.fail(uiError)
                    return
                }

                // Indicate success
                promise.success(Void())
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
                let uiError = ErrorHandler().fromAppAuthError(
                    error: error!,
                    errorCode: ErrorCodes.authorizationCodeGrantFailed)
                promise.fail(uiError)
                return
            }

            // Make a sanity check to ensure we have tokens
            if tokenResponse == nil || tokenResponse!.accessToken == nil {
                let message = "No tokens were received in the Authorization Code Grant message"
                promise.fail(ErrorHandler().fromMessage(message: message))
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

        do {
            // First get metadata
            let metadata = try self.getMetadata()
                .await()

            // Create the refresh token grant request
            let request = OIDTokenRequest(
                configuration: metadata,
                grantType: OIDGrantTypeRefreshToken,
                authorizationCode: nil,
                redirectURL: nil,
                clientID: self.configuration.clientId,
                clientSecret: nil,
                scope: nil,
                refreshToken: self.tokenData!.refreshToken!,
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
                        KeychainWrapper.standard.removeObject(forKey: self.storageKey)
                        self.tokenData = nil
                        promise.success(Void())
                        return
                    }

                    // Handle other errors
                    let uiError = ErrorHandler().fromAppAuthError(
                        error: error!,
                        errorCode: ErrorCodes.authorizationCodeGrantFailed)
                    promise.fail(uiError)
                    return
                }

                // Make a sanity check to ensure we have tokens
                if tokenResponse == nil || tokenResponse!.accessToken == nil {
                    let message = "No tokens were received in the Refresh Token Grant message"
                    promise.fail(ErrorHandler().fromMessage(message: message))
                    return
                }

                // Save received tokens and return success
                self.saveTokens(tokenResponse: tokenResponse!)
                promise.success(Void())
            }
        } catch {

            // Handle errors
            promise.fail(ErrorHandler().fromException(error: error))
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
        if self.tokenData != nil {

            // Maintain the existing refresh token unless we received a new 'rolling' refresh token
            if newTokenData.refreshToken == nil {
                newTokenData.refreshToken = self.tokenData!.refreshToken
            }

            // Maintain the existing id token if required, which may be needed for logout
            if newTokenData.idToken == nil {
                newTokenData.idToken = self.tokenData!.idToken
            }
        }

        // Update memory storage
        self.tokenData = newTokenData

        // Save tokens to the keychain, where they are encrypted
        let encoder = JSONEncoder()
        let jsonText = try? encoder.encode(self.tokenData)
        if jsonText != nil {
            KeychainWrapper.standard.set(jsonText!, forKey: self.storageKey)
        }
    }

    /*
     * Check for a particular AppAuth error
     */
    private func matchesAppAuthError(error: Error, domain: String, code: Int) -> Bool {
        let authError = error as NSError
        return authError.domain == domain && authError.code == code
    }
}
