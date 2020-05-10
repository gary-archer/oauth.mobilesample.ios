import Foundation
import AppAuth

/*
 * A class to manage error translation
 */
struct ErrorHandler {

    static let AppAuthNamespace = "org.openid.appauth"

    /*
     * Return a typed error from a general UI exception
     */
    static func fromException (error: Error) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        // Create the error
        uiError = UIError(
            area: "Mobile UI",
            errorCode: ErrorCodes.generalUIError,
            userMessage: "A technical problem was encountered in the UI")

        // Update from the caught exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
        return uiError!
    }

    /*
     * Used to throw programming level errors that should not occur
     * Equivalent to throwing a RuntimeException in Android
     */
    static func fromMessage(message: String) -> UIError {

        return UIError(
            area: "Mobile UI",
            errorCode: ErrorCodes.generalUIError,
            userMessage: message)
    }

    /*
     * Return an error to short circuit execution
     */
    static func fromLoginRequired() -> UIError {

        return UIError(
            area: "Login",
            errorCode: ErrorCodes.loginRequired,
            userMessage: "A login is required so the API call was aborted")
    }

    /*
     * Return an error to indicate that the Safari View Controller window was closed
     */
    static func fromRedirectCancelled() -> UIError {

        return UIError(
            area: "Redirect",
            errorCode: ErrorCodes.redirectCancelled,
            userMessage: "The redirect request was cancelled")
    }

    /*
     * Handle errors triggering login requests
     */
    static func fromLoginRequestError(error: Error) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        uiError = UIError(
            area: "Login",
            errorCode: ErrorCodes.loginRequestFailed,
            userMessage: "A technical problem occurred during login processing"
        )

        // Update it from the expcetion
        if ErrorHandler.isAppAuthError(error: error) {
            ErrorHandler.updateFromAppAuthException(error: error, uiError: uiError!)
        } else {
            ErrorHandler.updateFromException(error: error, uiError: uiError!)
        }

        return uiError!
    }

    /*
     * Handle errors processing login responses
     */
    static func fromLoginResponseError(error: Error) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        uiError = UIError(
            area: "Login",
            errorCode: ErrorCodes.loginResponseFailed,
            userMessage: "A technical problem occurred during login processing"
        )

        // Update it from the expcetion
        if ErrorHandler.isAppAuthError(error: error) {
            ErrorHandler.updateFromAppAuthException(error: error, uiError: uiError!)
        } else {
            ErrorHandler.updateFromException(error: error, uiError: uiError!)
        }

        return uiError!
    }

    /*
     * Handle logout errors
     */
    static func fromLogoutRequestError(error: Error) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        // Create the error
        uiError = UIError(
            area: "Logout",
            errorCode: ErrorCodes.logoutRequestFailed,
            userMessage: "A technical problem occurred during logout processing")

        // Update it from the expcetion
        if ErrorHandler.isAppAuthError(error: error) {
            ErrorHandler.updateFromAppAuthException(error: error, uiError: uiError!)
        } else {
            ErrorHandler.updateFromException(error: error, uiError: uiError!)
        }

        return uiError!
    }

    /*
     * Handle token related errors
     */
    static func fromTokenError(error: Error, errorCode: String) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        // Create the error
        uiError = UIError(
            area: "Token",
            errorCode: errorCode,
            userMessage: "A technical problem occurred during token processing")

        // Update it from the expcetion
        if ErrorHandler.isAppAuthError(error: error) {
            ErrorHandler.updateFromAppAuthException(error: error, uiError: uiError!)
        } else {
            ErrorHandler.updateFromException(error: error, uiError: uiError!)
        }

        return uiError!
    }

    /*
     * Get details when we cannot connect to the API
     */
    static func fromApiRequestError(error: Error, url: String) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        uiError = UIError(
            area: "API",
            errorCode: ErrorCodes.apiNetworkError,
            userMessage: "A network problem occurred when the UI called the server")

        ErrorHandler.updateFromException(error: error, uiError: uiError!)
        uiError!.url = url
        return uiError!
    }

    /*
     * Get details from the HTTP response
     */
    static func fromApiResponseError(response: HTTPURLResponse, data: Data?, url: String) -> UIError {

        // Set base fields
        let error = UIError(
            area: "API",
            errorCode: ErrorCodes.apiResponseError,
            userMessage: "A technical problem occurred when the UI called the server")
        error.statusCode = response.statusCode
        error.url = url

        // Process response errors when received
        if data != nil {
            self.updateFromApiErrorResponse(error: error, responseData: data!)
        }

        return error
    }

    /*
     * Try to update the default API error with response details
     */
    private static func updateFromApiErrorResponse(error: UIError, responseData: Data) {

        if let json = try? JSONSerialization.jsonObject(with: responseData, options: []) {

            if let fields = json as? [String: Any] {

                // Read standard fields that the API returns
                let errorCode = fields["code"] as? String
                let errorMessage = fields["message"] as? String
                if errorCode != nil && errorMessage != nil {
                    error.errorCode = errorCode!
                    error.details = errorMessage!
                }

                // For 500 errors also read additional details that are used for error lookup
                let area = fields["area"] as? String
                let id = fields["id"] as? Int
                let utcTime = fields["utcTime"] as? String
                if area != nil && id != nil && utcTime != nil {
                    error.setApiErrorDetails(area: area!, instanceId: id!, utcTime: utcTime!)
                }
            }
        }
    }

    /*
     * See if the error was returned from AppAuth libraries
     */
    private static func isAppAuthError(error: Error) -> Bool {

        let authError = error as NSError
        return authError.domain.contains(ErrorHandler.AppAuthNamespace)
    }

    /*
     * Get details from the AppAuth error
     */
    private static func updateFromAppAuthException(error: Error, uiError: UIError) {

        let authError = error as NSError

        // Get the AppAuth error category from the domain field and shorten it for readability
        let category = authError.domain.replacingOccurrences(
            of: ErrorHandler.AppAuthNamespace,
            with: "").uppercased()

        // Set other fields from the AppAuth error and extract the error code
        uiError.details = authError.localizedDescription
        uiError.appAuthCode = "\(category) / \(authError.code)"
    }

    /*
     * Get details from the exception
     */
    private static func updateFromException(error: Error, uiError: UIError) {
        uiError.details = error.localizedDescription
    }
}
