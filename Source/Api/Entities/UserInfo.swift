/*
 * User info received from the API
 */
struct UserInfo: Decodable {

    // These values originate from OAuth user info
    let givenName: String
    let familyName: String

    // This value originates from the API's own data
    let regions: [String]
}
