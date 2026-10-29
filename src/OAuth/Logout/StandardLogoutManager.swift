import Foundation
import AppAuth

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
}
