import Foundation

/*
* A class to contain data for routing
*/
class ViewRouter: ObservableObject {

    // The current view and its parameters
    @Published var currentViewType: Any.Type = CompaniesView.Type.self
    @Published var params: [Any] = [Any]()

    // Callbacks to the app view
    var handleOAuthDeepLink: ((URL) -> Bool)

    // This is set to false when the ASWebAuthenticationSession window is on top
    var isTopMost: Bool = true

    init(handleOAuthDeepLink: @escaping ((URL) -> Bool)) {
        self.handleOAuthDeepLink = handleOAuthDeepLink
    }

    /*
     * Deep links while running are more complicated and involve interaction with the app view
     */
    func handleDeepLink(url: URL) {

        // Handle OAuth responses specially
        let processed = self.handleOAuthDeepLink(url)
        if !processed {

            // Do not handle deep links when the ASWebAuthenticationSession window is top most
            if self.isTopMost {

                // Handle the link in the standard way
                self.processDeepLink(url: url)

                // Notify the parent, since deep linking to the same view requires reload actions
                // let oldViewType = self.currentViewType
                // let isSameView = oldViewType == self.currentViewType
                // self.onDeepLinkCompleted!(isSameView)
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
     * Handle standard deep link messages to change location within the app
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
