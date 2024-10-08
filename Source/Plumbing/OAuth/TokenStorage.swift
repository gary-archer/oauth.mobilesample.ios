import Foundation
import KeychainSwift

/*
 * A helper class to deal with token storage and the keychain
 */
class TokenStorage {

    private var tokenData: TokenData?
    private let storageKey = "com.authsamples.finalmobileapp.tokendata"
    private let keychain = KeychainSwift()

    /*
     * Try to load token data from storage on application startup
     */
    func loadTokens() {

        // Try the load
        let jsonText = keychain.get(self.storageKey)
        if jsonText == nil {
            return
        }

        // Try to deserialize
        let data = jsonText!.data(using: .utf8)
        let decoder = JSONDecoder()
        self.tokenData = try? decoder.decode(TokenData.self, from: data!)
        return
    }

    /*
     * Get tokens if the user has logged in or they have been loaded from storage
     */
    func getTokens() -> TokenData? {
        return self.tokenData
    }

    /*
     * Save tokens to the keychain, where they are encrypted and private to this app
     */
    func saveTokens(newTokenData: TokenData) {
        self.tokenData = newTokenData
        self.saveTokenData()
    }

    /*
     * Remove tokens when we logout or the refresh token expires
     */
    func removeTokens() {
        self.tokenData = nil
        keychain.delete(self.storageKey)
    }

    /*
     * A hacky method for testing, to update token storage to make the access token act like it is expired
     */
    func expireAccessToken() {

        if self.tokenData != nil {
            self.tokenData!.accessToken = "\(self.tokenData!.accessToken!)x"
            self.saveTokenData()
        }
    }

    /*
     * A hacky method for testing, to update token storage to make the refresh token act like it is expired
     */
    func expireRefreshToken() {

        if self.tokenData != nil {
            self.tokenData!.accessToken = "\(self.tokenData!.accessToken!)x"
            self.tokenData!.refreshToken = "\(self.tokenData!.refreshToken!)x"
            self.saveTokenData()
        }
    }

    /*
     * Load token data from storage
     */
    private func saveTokenData() {

        let encoder = JSONEncoder()
        let jsonText = try? encoder.encode(self.tokenData)
        if jsonText != nil {
            keychain.set(jsonText!, forKey: self.storageKey)
        }
    }
}
