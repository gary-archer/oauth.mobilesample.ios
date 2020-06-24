import Foundation
import AppAuth
import SwiftCoroutine

/*
 * The Okta implementation is standards based
 */
struct OktaLogoutManager: LogoutManager {

    private let configuration: OAuthConfiguration

    init(configuration: OAuthConfiguration) {
        self.configuration = configuration
    }

    /*
     * For Okta this is a no op since it has a standard end session endpoint
     */
    func updateMetadata(metadata: OIDServiceConfiguration) throws -> OIDServiceConfiguration {
        return metadata
    }

    /*
     * Return the end session request object in a standard way
     */
    func createEndSessionRequest(
        metadata: OIDServiceConfiguration,
        idToken: String,
        postLogoutRedirectUri: URL) -> OIDEndSessionRequest {

        return OIDEndSessionRequest(
            configuration: metadata,
            idTokenHint: idToken,
            postLogoutRedirectURL: postLogoutRedirectUri,
            state: "",
            additionalParameters: nil)
    }

    /*
     * Treat state mismatch errors as success, since Okta does not return a state in the response
     */
    func isExpectedError(error: Error) -> Bool {
        return error.localizedDescription.lowercased().contains("state mismatch")
    }
}
