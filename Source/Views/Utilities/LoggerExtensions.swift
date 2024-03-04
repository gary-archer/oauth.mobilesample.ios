import OSLog

/*
 * Used when I want to use the console to capture logs on a device or simulator
 * https://www.avanderlee.com/debugging/oslog-unified-logging/
 *
 * Use like this:
 * - import OSLog
 * - Logger.trace.info("my trace output")
 *
 * Then perform these actions:
 * - Run the macOS console app
 * - Select the connected simulator or device
 * - Select com.authsamples.basicmobileapp as the subsystem
 * - Ensure that Action / Include Info Messages is selected in the menu of the console app
 */
extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let trace = Logger(subsystem: subsystem, category: "trace")
}
