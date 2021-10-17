import Foundation
import AppAuth

/*
 * A class to manage error translation
 */
struct ErrorHandler {

    static let AppAuthNamespace = "org.openid.appauth."

    /*
     * Translate a general exception into a form ready for display
     */
    static func fromException(
        error: Error,
        errorCode: String? = nil,
        userMessage: String? = nil) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        // Initialise top level fields
        let message = userMessage != nil ? userMessage! : "A technical problem was encountered in the UI"
        let code = errorCode != nil ? errorCode! : ErrorCodes.generalUIError

        // Create the error object
        uiError = UIError(
            area: "Mobile UI",
            errorCode: code,
            userMessage: message)

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

        // Update it from the exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
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

        // Update it from the exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
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

        // Update it from the exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
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

        // Update it from the exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
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
     * Add iOS details from the exception
     */
    private static func updateFromException(error: Error, uiError: UIError) {

        let nsError = error as NSError
        var details = error.localizedDescription

        // Get iOS common details
        if nsError.domain.count > 0 {
            details += "\nDomain: \(nsError.domain)"
        }
        if nsError.code != 0 {
            details += "\nCode: \(nsError.code)"
        }
        for (name, value) in nsError.userInfo {
            details += "\n\(name): \(value)"
        }

        // Get details to assist with lookups in AppAuth error files
        if nsError.domain.contains(ErrorHandler.AppAuthNamespace) {
            let category = ErrorHandler.getAppAuthCategory(domain: nsError.domain)
            uiError.appAuthCode = "\(category) / \(nsError.code)"
        }

        uiError.details = details
    }

    /*
     * Translate the error category to a readable form
     */
    private static func getAppAuthCategory(domain: String) -> String {

        // Remove the namespace
        let category = domain.replacingOccurrences(
            of: ErrorHandler.AppAuthNamespace,
            with: "")
                .uppercased()

        // Remove the OAUTH prefix, to form a value such as 'TOKEN'
        return category.replacingOccurrences(
            of: "OAUTH_",
            with: "")
                .uppercased()
    }
}
