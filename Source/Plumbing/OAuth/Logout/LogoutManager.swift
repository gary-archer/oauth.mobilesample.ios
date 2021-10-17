import Foundation
import AppAuth
import SwiftCoroutine

/*
 * An abstraction to deal with differences between providers
 */
protocol LogoutManager {

    // Deal with metadata and the end session endpoint
    func updateMetadata(metadata: OIDServiceConfiguration) throws -> OIDServiceConfiguration

    // Return the end session request object
    func createEndSessionRequest(
        metadata: OIDServiceConfiguration,
        idToken: String,
        postLogoutRedirectUri: URL) -> OIDEndSessionRequest

    // Prevent errors for expected scenarios
    func isExpectedError(error: Error) -> Bool
}
