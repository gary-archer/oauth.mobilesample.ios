/*
 * OAuth specific configuration
 */
struct OAuthConfiguration: Decodable {

    // The authority base URL
    let authority: String

    // The identifier for our mobile app
    let clientId: String

    // The interstitial page that receives the login response
    let redirectUri: String

    // The interstitial page that receives the logout response
    let postLogoutRedirectUri: String

    // OAuth scopes being requested, for use when calling APIs after login
    let scope: String

    // The user info endpoint
    let userInfoEndpoint: String

    // Some Authorization Servers, such as AWS Cognito, use a custom logout endpoint
    let customLogoutEndpoint: String

    // The deep linking base URL is configured to workaround an AppAuth library bug
    let deepLinkBaseUrl: String
}
