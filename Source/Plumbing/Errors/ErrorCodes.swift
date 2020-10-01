import Foundation

/*
 * Error codes that the UI can program against
 */
struct ErrorCodes {

    // A general exception in the UI
    static let generalUIError = "ui_error"

    // A problem loading configuration
    static let configurationError = "configuration_error"

    // Used to indicate that the API cannot be called until the user logs in
    static let loginRequired = "login_required"

    // Used to indicaten that the Safari View Controller was cancelled
    static let redirectCancelled = "redirect_cancelled"

    // A technical error starting a login request, such as contacting the metadata endpoint
    static let loginRequestFailed = "login_request_failed"

    // A technical error processing the login response containing the authorization code
    static let loginResponseFailed = "login_response_failed"

    // A technical error exchanging the authorization code for tokens
    static let authorizationCodeGrantFailed = "authorization_code_grant"

    // A technical error refreshing tokens
    static let refreshTokenGrantFailed = "refresh_token_grant"

    // A technical error during a logout redirect
    static let logoutRequestFailed = "logout_request_failed"

    // An error making an API call to get data
    static let apiNetworkError = "api_network_error"

    // An error response fropm the API
    static let apiResponseError = "api_response_error"

    // Returned by the API if an unauthorised company is requested
    static let companyNotFound = "company_not_found"

    // Returned by the API when the user edits the browser URL and supplies a non numeric company id
    static let invalidCompanyId = "invalid_company_id"
}
