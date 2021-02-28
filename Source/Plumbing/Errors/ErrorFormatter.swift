// swiftlint:disable function_body_length

import Foundation
import SwiftUI

/*
* A helper class to format error fields for display
*/
struct ErrorFormatter {

    /*
     * Return a collection of error lines from the error object
     */
    static func getErrorLines(error: UIError) -> [ErrorLine] {

        var result: [ErrorLine] = []

        /* FIELDS FOR THE END USER */

        // Keep the user informed and suggest an action
        result.append(
            ErrorLine(
                name: "User Action",
                value: "Please retry the operation",
                valueColour: Colors.paleGreen
            )
        )

        // Give the user summary level info, such as 'Network error'
        if !error.userMessage.isEmpty {
            result.append(
                ErrorLine(
                    name: "Info",
                    value: error.userMessage,
                    valueColour: Color.black
                )
            )
        }

        /* FIELDS FOR TECHNICAL SUPPORT STAFF */

        // Show the time of the error
        result.append(
            ErrorLine(
                name: "UTC Time",
                value: error.utcTime,
                valueColour: Color.black
            )
        )

        // Indicate the area of the system, such as which component failed
        if !error.area.isEmpty {
            result.append(
                ErrorLine(
                    name: "Area",
                    value: error.area,
                    valueColour: Color.black
                )
            )
        }

        // Indicate the type of error
        if !error.errorCode.isEmpty {
            result.append(
                ErrorLine(
                    name: "Error Code",
                    value: error.errorCode,
                    valueColour: Color.black
                )
            )
        }

        // Show the AppAuth error code if applicable
        if !error.appAuthCode.isEmpty {
            result.append(
                ErrorLine(
                    name: "AppAuth Code",
                    value: error.appAuthCode,
                    valueColour: Color.black
                )
            )
        }

        // Link to API logs if applicable
        if error.instanceId != 0 {
            result.append(
                ErrorLine(
                    name: "Instance Id",
                    value: String(error.instanceId),
                    valueColour: Color.red
                )
            )
        }

        // Show an HTTP status if applicable
        if error.statusCode != 0 {
            result.append(
                ErrorLine(
                    name: "Status Code",
                    value: String(error.statusCode),
                    valueColour: Color.black
                )
            )
        }

        /* FIELDS FOR DEVELOPERS */

        // Show details for some types of error
        if !error.details.isEmpty {
            result.append(
                ErrorLine(
                    name: "Details",
                    value: String(error.details),
                    valueColour: Color.black
                )
            )
        }

        // Show the URL that failed if applicable
        if !error.url.isEmpty {
            result.append(
                ErrorLine(
                    name: "URL",
                    value: String(error.url),
                    valueColour: Color.black
                )
            )
        }

        // Output a stack trace in debug builds
        // https://stackoverflow.com/questions/30754796/how-to-print-call-stack-in-swift
        #if DEBUG
        if error.stack.count > 0 {
            let stackTrace = ErrorFormatter.getFormattedStackTrace(stack: error.stack)
            result.append(
                ErrorLine(
                    name: "Stack",
                    value: String(stackTrace),
                    valueColour: Color.black
                )
            )
        }
        #endif

        return result
    }

    /*
     * Try to get the stack trace into a format for output
     * I would like to demangle the call stack but currently there seems to be no clean way to do that
     */
    private static func getFormattedStackTrace(stack: [String]) -> String {

        var result: String = ""
        for symbol: String in stack {
            result.append(symbol)
            result.append("\n\n")
        }

        return result
    }
}
