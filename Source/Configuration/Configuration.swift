/*
 * Represents the configuration file as an object
 */
struct Configuration: Decodable {

    // Application properties
    let app: AppConfiguration

    // OAuth plumbing properties
    let oauth: OAuthConfiguration
}
