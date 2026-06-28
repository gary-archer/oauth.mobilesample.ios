import Foundation

/*
 * A helper class to output error details to the console and avoid end users
 */
struct ErrorConsoleReporter {

    /*
     * Output names and values
     */
    static func output(error: UIError) {

        let lines = ErrorFormatter.getErrorLines(error: error)
        lines.forEach { line in
            NSLog("finalmobileapp Error: \(line.name) = \(line.value)")
        }
    }
}
