import Foundation

/*
 * A class to manage parsing of deep link notifications
 */
class DeepLinkHelper {

    /*
     * Navigate to a deep linking URL such as 'https://mobile.authsamples.com/basicmobileapp/deeplink/company/2'
     * Our example is simplistic since we only have a couple of screens
     */
    static func handleDeepLink(url: URL) -> (target: Any.Type, params: [Any]) {

        var newView: Any.Type = CompaniesView.Type.self
        var newViewParams = [Any]()

        // Get the relative path
        let deepLinkBasePath = "/basicmobileapp/deeplink"
        let lowerCasePath = url.path.lowercased()
        if lowerCasePath.starts(with: deepLinkBasePath) {

            // If we have a company id then move to the transactions view
            let relativePath = lowerCasePath.replacingOccurrences(of: deepLinkBasePath + "/", with: "")
            let companyId = self.getDeepLinkedCompanyId(path: relativePath)
            if companyId != nil {
                newView = TransactionsView.Type.self
                newViewParams = [companyId!]
            }
        }

        return (target: newView, params: newViewParams)
    }

    /*
     * See if the hash fragment is of the form 'company/2' and if so return the id
     */
    static private func getDeepLinkedCompanyId(path: String) -> String? {

        let range = NSRange(location: 0, length: path.utf16.count)
        let regex = try? NSRegularExpression(pattern: "^company/(.+)")

        // See if we can match the first group
        if let match = regex?.firstMatch(in: path, options: [], range: range) {
            if let foundRange = Range(match.range(at: 1), in: path) {

                // If so return the first group which contains the company id
                return String(path[foundRange])
            }
        }

        return nil
    }
}
