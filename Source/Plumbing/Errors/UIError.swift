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
        self.utcTime = ""
        self.stack = Thread.callStackSymbols
        self.utcTime = DateUtils.dateToUtcDisplayString(date: Date())
    }

    /*
     * Update fields from an API response
     */
    func setApiErrorDetails(area: String, instanceId: Int, utcTime: String) {

        self.area = area
        self.instanceId = instanceId

        // The API returns an ISO8601 timestamp for the error time
        let date = DateUtils.apiErrorTimestampToDate(isoTimestamp: utcTime)
        if date != nil {
            self.utcTime = DateUtils.dateToUtcDisplayString(date: date!)
        }
    }
}
