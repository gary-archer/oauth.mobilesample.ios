/*
 * OAuth user info needed by the UI
 */
struct OAuthUserInfo: Decodable {
    let givenName: String
    let familyName: String
}
