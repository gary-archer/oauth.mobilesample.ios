import Foundation
import AppAuth

/*
 * A class to manage error translation
 */
struct ErrorHandler {

    /*
     * Return a typed error from a general UI exception
     */
    func fromException (error: Error) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        // Otherwise translate from the caught error
        uiError = UIError(
            area: "Mobile UI",
            errorCode: ErrorCodes.generalUIError,
            userMessage: "A technical problem was encountered in the UI")
        uiError!.details = error.localizedDescription
        return uiError!
    }

    /*
     * Used to throw programming level errors that should not occur
     * Equivalent to throwing a RuntimeException in Android
     */
    func fromMessage(message: String) -> UIError {

        return UIError(
            area: "Mobile UI",
            errorCode: ErrorCodes.generalUIError,
            userMessage: message)
    }

    /*
     * Return an error to short circuit execution
     */
    func fromLoginRequired() -> UIError {

        return UIError(
            area: "Login",
            errorCode: ErrorCodes.loginRequired,
            userMessage: "A login is required so the API call was aborted")
    }

    /*
     * Return an error to indicate that the Safari View Controller window was closed
     */
    func fromRedirectCancelled() -> UIError {

        return UIError(
            area: "Login",
            errorCode: ErrorCodes.loginCancelled,
            userMessage: "The redirect request was cancelled")
    }

    /*
     * Handle errors returned from AppAuth libraries
     */
    func fromAppAuthError(error: Error, errorCode: String) -> UIError {

        let authError = error as NSError

        // Create the error
        let uiError = UIError(
            area: "OAuth",
            errorCode: errorCode,
            userMessage: "A problem was encountered during a login related operation")

        // Get the AppAuth error category from the domain field and shorten it for readability
        let category = authError.domain.replacingOccurrences(of: "org.openid.appauth.", with: "").uppercased()

        // Set other fields from the AppAuth error and extract the error code
        uiError.details = error.localizedDescription
        uiError.appAuthCode = "\(category) / \(authError.code)"
        return uiError
    }

    /*
     * Get details when we cannot connect to the API
     */
    func fromApiRequestError(error: Error, url: String) -> UIError {

        let uiError = UIError(
            area: "API",
            errorCode: ErrorCodes.apiNetworkError,
            userMessage: "A network problem occurred when the UI called the server")
        uiError.details = error.localizedDescription
        uiError.url = url
        return uiError
    }

    /*
     * Get details from the HTTP response
     */
    func fromApiResponseError(response: HTTPURLResponse, data: Data?, url: String) -> UIError {

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
    private func updateFromApiErrorResponse(error: UIError, responseData: Data) {

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
                    error.area = area!
                    error.instanceId = id!
                    error.utcTime = utcTime!
                }
            }
        }
    }
}
