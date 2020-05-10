import Foundation

/*
 * Error codes that the UI can program against
 */
struct ErrorCodes {

    // Used to indicate that the API cannot be called until the user logs in
    static let loginRequired = "login_required"

    // Used to indicate that the Safari View Controller was cancelled
    static let loginCancelled = "login_cancelled"

    // A technical error processing the login response containing the authorization code
    static let loginResponseFailed = "login_response_failed"

    // A technical error exchanging the authorization code for tokens
    static let authorizationCodeGrantFailed = "authorization_code_grant"

    // A technical error refreshing tokens
    static let refreshTokenGrantFailed = "refresh_token_grant"

    // A technical error during a logout redirect
    static let logoutFailed = "logout_failed"

    // A general exception in the UI
    static let generalUIError = "ui_error"

    // An error making an API call to get data
    static let apiNetworkError = "api_network_error"

    // An error response fropm the API
    static let apiResponseError = "api_response_error"

    // Returned by the API when the user edits the browser URL and ties to access an unauthorised company
    static let companyNotFound = "company_not_found"

    // Returned by the API when the user edits the browser URL and supplies a non numeric company id
    static let invalidCompanyId = "invalid_company_id"
}
