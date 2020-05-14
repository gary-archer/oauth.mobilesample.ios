import Foundation

/*
 * A class to manage universal link notifications
 */
class DeepLinkHelper {

    /*
     * Return true if this is a login or logout response
     */
    static func isOAuthResponse() -> Bool {
        return true
    }

    /*
     * Update the location based on the deep link supplied
     */
    static func handleDeepLink(url: URL, viewRouter: ViewRouter) {

        var target: Any.Type = CompaniesView.Type.self
        var params = [Any]()

        // Only handle our deep linking URL
        if url.host != "authguidance-examples.com" {
            return
        }

        // Check for a hash fragment
        let hash = url.fragment
        if hash != nil {

            // If we have a company id then move to the transactions view
            let companyId = self.getDeepLinkedCompanyId(hashFragment: hash!)
            if companyId != nil {
                target = TransactionsView.Type.self
                params = [companyId!]
            }
        }

        // Update the view router so that navigation is triggered
        viewRouter.currentViewType = target
        viewRouter.params = params
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
