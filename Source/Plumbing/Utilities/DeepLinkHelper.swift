import Foundation

/*
 * A class to manage parsing of deep link notifications
 */
class DeepLinkHelper {

    /*
     * Calculate and return the new view
     */
    static func handleDeepLink(url: URL) -> (target: Any.Type, params: [Any]) {

        var newView: Any.Type = CompaniesView.Type.self
        var newViewParams = [Any]()

        // Check for a hash fragment
        let hash = url.fragment
        if hash != nil {

            // If we have a company id then move to the transactions view
            let companyId = self.getDeepLinkedCompanyId(hashFragment: hash!)
            if companyId != nil {
                newView = TransactionsView.Type.self
                newViewParams = [companyId!]
            }
        }

        return (target: newView, params: newViewParams)
    }

    /*
     * See if the hash fragment is of the form '#company=2' and if so return the id
     */
    static private func getDeepLinkedCompanyId(hashFragment: String) -> String? {

        let range = NSRange(location: 0, length: hashFragment.utf16.count)
        let regex = try? NSRegularExpression(pattern: "^company=(.+)")

        // See if we can match the first group
        if let match = regex?.firstMatch(in: hashFragment, options: [], range: range) {
            if let foundRange = Range(match.range(at: 1), in: hashFragment) {

                // If so return the first group which contains the company id
                let companyId = String(hashFragment[foundRange])
                return companyId
            }
        }

        return nil
    }
}
