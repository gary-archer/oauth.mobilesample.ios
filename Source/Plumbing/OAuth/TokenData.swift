/*
 * An object for storing OAuth tokens in memory
 */
class TokenData: Encodable, Decodable {
    var accessToken: String?
    var refreshToken: String?
    var idToken: String?
}
