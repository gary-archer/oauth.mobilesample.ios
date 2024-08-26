import Foundation

/*
 * A utility class for date time formatting
 */
struct DateUtils {

    /*
     * Return a date for display
     */
    static func dateToUtcDisplayString(date: Date) -> String {

        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "MMM dd yyyy HH:mm:ss"
        return formatter.string(from: date)
    }

    /*
     * Receive a timestamp from the API
     */
    static func apiErrorTimestampToDate(isoTimestamp: String) -> Date? {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.date(from: isoTimestamp)
    }
}
