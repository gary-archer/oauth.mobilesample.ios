import Foundation
import AppAuth
import SwiftCoroutine

/*
 * The Cognito implementation has some custom vendor specific behaviour
 */
struct CognitoLogoutManager: LogoutManager {

    private let configuration: OAuthConfiguration

    init(configuration: OAuthConfiguration) {
        self.configuration = configuration
    }

    /*
     * Cognito has no end session endpoint and does not return one in its metadata
     * So create an updated metadata object with its vendor specific logout URL
     */
    func updateMetadata(metadata: OIDServiceConfiguration) throws -> OIDServiceConfiguration {

        guard let logoutUri = URL(string: self.configuration.customLogoutEndpoint) else {
            let message = "Error creating URL for : \(self.configuration.customLogoutEndpoint)"
            throw ErrorHandler.fromMessage(message: message)
        }

        return OIDServiceConfiguration(
            authorizationEndpoint: metadata.authorizationEndpoint,
            tokenEndpoint: metadata.tokenEndpoint,
            issuer: metadata.issuer,
            registrationEndpoint: metadata.registrationEndpoint,
            endSessionEndpoint: logoutUri)
    }

    /*
     * Return the end session request object
     */
    func createEndSessionRequest(
        metadata: OIDServiceConfiguration,
        idToken: String,
        postLogoutRedirectUri: URL) -> OIDEndSessionRequest {

        // Build the logout request and include extra vendor specific parameters that Cognito requires
        return OIDEndSessionRequest(
            configuration: metadata,
            idTokenHint: idToken,
            postLogoutRedirectURL: postLogoutRedirectUri,
            state: "",
            additionalParameters: [
                "client_id": self.configuration.clientId,
                "logout_uri": postLogoutRedirectUri.absoluteString
            ])
    }

    /*
     * Treat state mismatch errors as success, since Cognito does not return a state in the response
     */
    func isExpectedError(error: Error) -> Bool {
        return error.localizedDescription.lowercased().contains("state mismatch")
    }
}
