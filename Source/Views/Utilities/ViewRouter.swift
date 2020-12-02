import Foundation

/*
* A class to manage main view navigation
*/
class ViewRouter: ObservableObject {

    // The current view and its navigation parameters
    @Published var currentViewType: Any.Type = CompaniesView.Type.self
    @Published var params: [Any] = [Any]()

    // This is set to false when the ASWebAuthenticationSession window is on top
    var isTopMost: Bool = true

    // Callbacks after navigation events
    private var handleOAuthDeepLink: ((URL) -> Bool)
    private var onDeepLinkCompleted: ((Bool) -> Void)

    init(
        handleOAuthDeepLink: @escaping ((URL) -> Bool),
        onDeepLinkCompleted: @escaping ((Bool) -> Void)) {

        self.handleOAuthDeepLink = handleOAuthDeepLink
        self.onDeepLinkCompleted = onDeepLinkCompleted
    }

    /*
     * Deep links include both user navigation events and OAuth redirect responses
     */
    func handleDeepLink(url: URL) {

        // Handle OAuth responses specially
        let processed = self.handleOAuthDeepLink(url)
        if !processed {

            // Do not handle deep links when the ASWebAuthenticationSession window is top most
            if self.isTopMost {

                // Handle standard deep link messages to change location within the app
                let result = DeepLinkHelper.handleDeepLink(url: url)
                self.changeMainView(newViewType: result.0, newViewParams: result.1)

                // Invoke the completion callback in case the view needs to update itself
                let oldViewType = self.currentViewType
                let isSameView = oldViewType == self.currentViewType
                self.onDeepLinkCompleted(isSameView)
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
