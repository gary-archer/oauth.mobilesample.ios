/*
 * User info received from the API
 */
struct UserInfoClaims: Decodable {
    let givenName: String
    let familyName: String
}
