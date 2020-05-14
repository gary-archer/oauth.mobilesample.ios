import Foundation
import LocalAuthentication

/*
 * A utility class to deal with device security
 */
struct DeviceSecurity {

    /*
     * Return true for secured devices
     */
    static func isDeviceSecured() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
}
