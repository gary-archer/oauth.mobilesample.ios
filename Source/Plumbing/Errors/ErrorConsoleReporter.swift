import Foundation

/*
* A helper class to output error details to the MacOS console during development
*/
struct ErrorConsoleReporter {

    /*
     * Output names and values
     */
    func output(error: UIError) {

        let lines = ErrorFormatter().getErrorLines(error: error)
        lines.forEach { line in
            NSLog("BasicMobileApp Error: \(line.name) = \(line.value)")
        }
    }
}
