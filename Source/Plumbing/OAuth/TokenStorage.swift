import Foundation
import SwiftKeychainWrapper

/*
 * A helper class to deal with token storage and the keychain
 */
class TokenStorage {

    private var tokenData: TokenData?
    private let storageKey = "com.authguidance.basicmobileapp.tokendata"

    /*
     * Load tokens when first requested
     */
    func loadTokens() -> TokenData? {

        if self.tokenData != nil {
            return self.tokenData
        }

        self.loadTokenData()
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
        KeychainWrapper.standard.removeObject(forKey: self.storageKey)
    }

    /*
     * A hacky method for testing, to update token storage to make the access token act like it is expired
     */
    func expireAccessToken() {

        if self.tokenData != nil {
            self.tokenData!.accessToken = "x\(self.tokenData!.accessToken!)x"
            self.saveTokenData()
        }
    }

    /*
     * A hacky method for testing, to update token storage to make the refresh token act like it is expired
     */
    func expireRefreshToken() {

        if self.tokenData != nil {
            self.tokenData!.accessToken = nil
            self.tokenData!.refreshToken = "x\(self.tokenData!.refreshToken!)x"
            self.saveTokenData()
        }
    }

    /*
     * Load token data from storage if required
     */
    private func loadTokenData() {

        // See if already loaded
        if self.tokenData != nil {
            return
        }

        // Otherwise try to load data
        let jsonText = KeychainWrapper.standard.string(forKey: self.storageKey)
        if jsonText == nil {
            return
        }

        // Deserialize if found
        let data = jsonText!.data(using: .utf8)
        let decoder = JSONDecoder()
        self.tokenData = try? decoder.decode(TokenData.self, from: data!)
    }

    /*
     * Load token data from storage
     */
    private func saveTokenData() {

        let encoder = JSONEncoder()
        let jsonText = try? encoder.encode(self.tokenData)
        if jsonText != nil {
            KeychainWrapper.standard.set(jsonText!, forKey: self.storageKey)
        }
    }
}
