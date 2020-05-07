import Foundation

/*
* A helper class to format error fields for display
*/
struct ErrorFormatter {

    /*
     * Return a collection of error lines from the error object
     */
    func getErrorLines(error: UIError) -> [ErrorLine] {

        var result: [ErrorLine] = []

        if !error.userMessage.isEmpty {
            result.append(ErrorLine(name: "User Message", value: error.userMessage))
        }

        if !error.area.isEmpty {
            result.append(ErrorLine(name: "Area", value: error.area))
        }

        if !error.errorCode.isEmpty {
            result.append(ErrorLine(name: "Error Code", value: error.errorCode))
        }

        if !error.appAuthCode.isEmpty {
            result.append(ErrorLine(name: "AppAuth Code", value: error.appAuthCode))
        }

        result.append(ErrorLine(name: "UTC Time", value: error.utcTime))

        if error.statusCode != 0 {
           result.append(ErrorLine(name: "Status Code", value: String(error.statusCode)))
        }

        if error.instanceId != 0 {
           result.append(ErrorLine(name: "Instance Id", value: String(error.instanceId)))
        }

        if !error.details.isEmpty {
            result.append(ErrorLine(name: "Details", value: String(error.details)))
        }

        if !error.url.isEmpty {
            result.append(ErrorLine(name: "URL", value: String(error.url)))
        }

        // Output a stack trace in debug builds
        // https://stackoverflow.com/questions/30754796/how-to-print-call-stack-in-swift
        #if DEBUG
        if error.stack.count > 0 {
            let stackTrace = self.getFormattedStackTrace(stack: error.stack)
            result.append(ErrorLine(name: "Stack", value: String(stackTrace)))
        }
        #endif

        return result
    }

    /*
     * Try to get the stack trace into a format for output
     * I would like to demangle the call stack but currently there seems to be no clean way to do that
     */
    private func getFormattedStackTrace(stack: [String]) -> String {

        var result: String = ""
        for symbol: String in stack {
            result.append(symbol)
            result.append("\n\n")
        }

        return result
    }
}
