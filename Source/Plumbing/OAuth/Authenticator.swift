import Foundation
import UIKit
import AppAuth

/*
 * An abstraction to represent authentication related operations
 */
protocol Authenticator {

    // Retrieve OpenID connect metadata
    func getMetadata() async throws

    // Return the current access token from secure mobile storage
    func getAccessToken() -> String?

    // Refresh the current access token
    func refreshAccessToken() async throws -> String

    // Start a login redirect on the main thread
    func startLoginRedirect(viewController: UIViewController) throws

    // Process a login response on a background thread
    func handleLoginResponse() async throws -> OIDAuthorizationResponse

    // Complete a login to get tokens
    func finishLogin(authResponse: OIDAuthorizationResponse) async throws

    // Start a logout redirect on the main thread
    func startLogoutRedirect(viewController: UIViewController) throws

    // Process a logout response on a background thread
    func handleLogoutResponse() async throws -> OIDEndSessionResponse?

    // When a deep link is received, see if it is a Claimed HTTPS scheme OAuth response
    func isOAuthResponse(responseUrl: URL) -> Bool

    // Resume AppAuth handling when we receive the login or logout response
    func resumeOperation(responseUrl: URL)

    // For testing, make the access token act expired
    func expireAccessToken()

    // For testing, make the refresh token act expired
    func expireRefreshToken()
}
