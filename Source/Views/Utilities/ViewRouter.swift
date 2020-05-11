import Foundation

/*
* A class to encapsulate navigation details
*/
class ViewRouter: ObservableObject {

    // The current view
    @Published var currentViewType: Any.Type = CompaniesView.Type.self

    // Data passed during navigation
    @Published var params: [Any] = [Any]()

    // This is set to false when a Safari View Controller is active
    var isTopMost: Bool = true

    /*
     * Update the location based on the deep link supplied
     */
    func handleDeepLink(url: URL) {

        // Do nothing during OAuth redirects, when the system browser is top most
        if !self.isTopMost {
            return
        }

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

        // Do the navigation
        self.currentViewType = target
        self.params = params
    }

    /*
     * See if the hash fragment is of the form '#company=2' and if so return the id
     */
    private func getDeepLinkedCompanyId(hashFragment: String) -> String? {

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
