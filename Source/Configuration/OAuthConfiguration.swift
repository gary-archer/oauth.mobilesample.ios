/*
 * OAuth specific configuration
 */
struct OAuthConfiguration: Decodable {

    // The authority base URL
    let authority: String

    // The identifier for our mobile app
    let clientId: String

    // The web domain name that hosts the interstitial page
    let webDomain: String

    // The interstitial page that receives the login response
    let loginRedirectPath: String

    // The interstitial page that receives the logout response
    let postLogoutRedirectPath: String

    // The deep link domain, also used to receive claimed HTTPS scheme OAuth responses
    let deepLinkDomain: String

    // The deep linking path on which the app is invoked, after login
    let loginActivatePath: String

    // The deep linking path on which the app is invoked, after login
    let postLogoutActivatePath: String

    // The Authorization Server endpoint used for logouts
    let logoutEndpoint: String

    // OAuth scopes being requested, for use when calling APIs after login
    let scope: String
}
