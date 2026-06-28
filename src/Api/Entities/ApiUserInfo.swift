/*
 * User attributes from the API's own data
 */
struct ApiUserInfo: Decodable {
    let title: String
    let regions: [String]
}
