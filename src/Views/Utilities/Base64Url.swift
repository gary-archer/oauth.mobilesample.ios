import Foundation
import LocalAuthentication

/*
 * A utility class to deal with device security
 */
struct Base64Url {

    /*
     * Return true for secured devices
     */
    static func decode(input: String) -> Data? {

        var updated = input
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
        if updated.count % 4 != 0 {
            updated.append(String(repeating: "=", count: 4 - updated.count % 4))
        }

        return Data(base64Encoded: updated)
    }
}
