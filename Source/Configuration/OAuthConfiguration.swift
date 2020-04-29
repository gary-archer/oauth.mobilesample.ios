/*
 * OAuth specific configuration
 */
struct OAuthConfiguration: Decodable {
    let authority: String
    let clientId: String
    let redirectUri: String
    let logoutEndpoint: String
    let postLogoutRedirectUri: String
    let scope: String
}
