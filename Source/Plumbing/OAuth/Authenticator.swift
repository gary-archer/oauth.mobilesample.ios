import Foundation
import UIKit
import AppAuth
import SwiftCoroutine

/*
 * An abstraction to represent authentication related operations
 */
protocol Authenticator {

    // Query the login state
    func isLoggedIn() -> Bool

    // Return the current access token from secure mobile storage
    func getAccessToken() -> CoFuture<String>

    // Refresh the current access token
    func refreshAccessToken() -> CoFuture<String>

    // Start a login redirect
    func startLogin(viewController: UIViewController) -> CoFuture<OIDAuthorizationResponse>

    // When a deep link is received, see if it is a Claimed HTTPS scheme OAuth response
    func isOAuthResponse(responseUrl: URL) -> Bool

    // Resume AppAuth handling when we receive the login or logout response
    func resumeOperation(responseUrl: URL)

    // Complete a login
    func finishLogin(authResponse: OIDAuthorizationResponse) -> CoFuture<Void>

    // Perform a logout
    func logout(viewController: UIViewController) -> CoFuture<Void>

    // For testing, make the access token act expired
    func expireAccessToken()

    // For testing, make the refresh token act expired
    func expireRefreshToken()
}
