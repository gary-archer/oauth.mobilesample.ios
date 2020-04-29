import SwiftUI

/*
* An error entity whose fields are rendered when there is a problem
*/
class UIError: Error {

    // Fields populated during error translation
    var area: String
    var errorCode: String
    var userMessage: String
    var statusCode: Int
    var utcTime: String
    var appAuthCode: String
    var instanceId: Int
    var details: String
    var url: String
    let stack: [String]

    /*
     * Create the error form supportable fields
     */
    init(area: String, errorCode: String, userMessage: String) {
        self.area = area
        self.errorCode = errorCode
        self.userMessage = userMessage
        self.statusCode = 0
        self.appAuthCode = ""
        self.instanceId = 0
        self.details = ""
        self.url = ""

        // Format the date
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "MMM dd yyyy HH:mm"
        self.utcTime = formatter.string(from: now)

        // Record the stack trace
        self.stack = Thread.callStackSymbols
    }

    /*
     * Return whether we contain an error
     */
    func isEmpty() -> Bool {
        return self.errorCode.isEmpty
    }
}
