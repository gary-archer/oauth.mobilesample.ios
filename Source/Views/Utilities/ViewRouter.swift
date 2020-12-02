import Foundation

/*
* A class to contain data for routing
*/
class ViewRouter: ObservableObject {

    // The current view and its parameters
    @Published var currentViewType: Any.Type = CompaniesView.Type.self
    @Published var params: [Any] = [Any]()

    // This is set to false when the ASWebAuthenticationSession window is on top
    var isTopMost: Bool = true

    // Callbacks to the app view
    var handleOAuthDeepLink: ((URL) -> Bool)?
    var onDeepLinkCompleted: ((Bool) -> Void)?

    /*
     * Deep links while running are more complicated and involve interaction with the app view
     */
    func handleDeepLink(url: URL) {

        // Sanity check
        if self.handleOAuthDeepLink == nil || self.onDeepLinkCompleted == nil {
            return
        }

        // Handle OAuth responses specially
        let processed = self.handleOAuthDeepLink!(url)
        if !processed {

            // Do not handle deep links when the ASWebAuthenticationSession window is top most
            if self.isTopMost {

                // Handle standard deep link messages to change location within the app
                let result = DeepLinkHelper.handleDeepLink(url: url)
                self.changeMainView(newViewType: result.0, newViewParams: result.1)

                // Notify the parent, since deep linking to the same view requires reload actions
                let oldViewType = self.currentViewType
                let isSameView = oldViewType == self.currentViewType
                self.onDeepLinkCompleted!(isSameView)
            }
        }
    }

    /*
     * Called to change the current main view
     */
    func changeMainView(newViewType: Any.Type, newViewParams: [Any]) {

        self.currentViewType = newViewType
        self.params = newViewParams
    }

    /*
     * Some operations are disabled in this view
     */
    func isInLoginRequired() -> Bool {
        return self.currentViewType == LoginRequiredView.Type.self
    }
}
