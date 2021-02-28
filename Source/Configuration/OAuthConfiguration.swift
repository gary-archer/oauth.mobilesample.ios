/*
 * OAuth specific configuration
 */
struct OAuthConfiguration: Decodable {

    // The authority base URL
    let authority: String

    // The identifier for our mobile app
    let clientId: String

    // The base URL for interstitial post login pages
    let webBaseUrl: String

    // The interstitial page that receives the login response
    let loginRedirectPath: String

    // The interstitial page that receives the logout response
    let postLogoutRedirectPath: String

    // The base URL for deep linking
    let deepLinkBaseUrl: String

    // The deep linking path on which the app is invoked, after login
    let loginActivatePath: String

    // The deep linking path on which the app is invoked, after login
    let postLogoutActivatePath: String

    // OAuth scopes being requested, for use when calling APIs after login
    let scope: String

    // Some Authorization Servers, such as AWS Cognito, use a custom logout endpoint
    let customLogoutEndpoint: String

    // Identity provider specific details might be configured by an install program
    let idpParameterName: String
    let idpParameterValue: String
}
