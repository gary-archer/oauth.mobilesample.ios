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

    // For testing, make the access token act expired
    func expireAccessToken()

    // For testing, make the refresh token act expired
    func expireRefreshToken()

    // Start a login redirect
    func startLogin(viewController: UIViewController) -> CoFuture<OIDAuthorizationResponse>

    // Complete a login
    func finishLogin(authResponse: OIDAuthorizationResponse) -> CoFuture<Void>

    // Perform a logout
    func logout(viewController: UIViewController) -> CoFuture<Void>
}
