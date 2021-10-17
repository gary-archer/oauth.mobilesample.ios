/*
 * User info received from the API
 */
struct UserInfo: Decodable {
    let givenName: String
    let familyName: String
}
