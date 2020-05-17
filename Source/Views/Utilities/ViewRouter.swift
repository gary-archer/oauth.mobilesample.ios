import Foundation

/*
* A class to contain data for routing
*/
class ViewRouter: ObservableObject {

    // The current view and its parameters
    @Published var currentViewType: Any.Type?
    @Published var params: [Any] = [Any]()

    // Callbacks to the app view
    var handleOAuthDeepLink: ((URL) -> Bool)?
    var onDeepLinkCompleted: ((Bool) -> Void)?

    // This is set to false when the ASWebAuthenticationSession window is on top
    var isTopMost: Bool = true

    /*
     * Startup deep links simply switch the initial view properties
     */
    func handleStartupDeepLink(url: URL) {
        self.processDeepLink(url: url)
    }

    /*
     * Deep links while running are more complicated and involve interaction with the app view
     */
    func handleDeepLink(url: URL) {

        if self.handleOAuthDeepLink == nil || self.onDeepLinkCompleted == nil {
            return
        }

        // Let the parent handle OAuth responses
        let processed = self.handleOAuthDeepLink!(url)
        if !processed {

            // Do not handle deep links when the ASWebAuthenticationSession window is top most
            if self.isTopMost {

                // Handle the link in the standard way
                let oldViewType = self.currentViewType
                self.processDeepLink(url: url)

                // Notify the parent, since deep linking to the same view requires reload actions
                let isSameView = oldViewType != nil && oldViewType == self.currentViewType
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
     * Do the parsing and then change view properties
     */
    private func processDeepLink(url: URL) {

        let result = DeepLinkHelper.handleDeepLink(url: url)
        self.changeMainView(newViewType: result.0, newViewParams: result.1)
    }

    /*
     * Some operations are disabled in this view
     */
    func isInLoginRequired() -> Bool {
        return self.currentViewType == LoginRequiredView.Type.self
    }
}
