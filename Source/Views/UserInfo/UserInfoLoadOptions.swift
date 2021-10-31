/*
 * Special logic related to loading user info
 */
struct UserInfoLoadOptions {
    var isDeviceSecured: Bool
    var reload: Bool
    var isInLoggedOutView: Bool
    var causeError: Bool
}
