/*
 * Represents the configuration file as an object
 */
struct Configuration: Decodable {
    let app: AppConfiguration
    let oauth: OAuthConfiguration
}
