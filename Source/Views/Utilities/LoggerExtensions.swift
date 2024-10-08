import OSLog

/*
 * Used when I want to use the console to capture logs on a device or simulator
 * https://www.avanderlee.com/debugging/oslog-unified-logging/
 *
 * Import and use with code like this:
 * - import OSLog
 * - Logger.trace.info("my trace output")
 *
 * Then perform these actions:
 * - Run the macOS console app
 * - Select the connected simulator or device
 * - Filter on com.authsamples.finalmobileapp and select the subsystem option
 * - Ensure that Action / Include Info Messages is selected in the menu of the console app
 * - Select the Start option to capture messages
 */
extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let trace = Logger(subsystem: subsystem, category: "trace")
}
