import Foundation
import AppAuth
import SwiftCoroutine

/*
 * A logout implementation based on draft standards
 */
struct StandardLogoutManager: LogoutManager {

    private let configuration: OAuthConfiguration

    init(configuration: OAuthConfiguration) {
        self.configuration = configuration
    }

    /*
     * This is a no op since the end session endpoint does not need updating
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
     * Treat state mismatch errors as success, since a state is not always returned in the response
     */
    func isExpectedError(error: Error) -> Bool {
        return error.localizedDescription.lowercased().contains("state mismatch")
    }
}
