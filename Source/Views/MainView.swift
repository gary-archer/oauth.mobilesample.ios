import SwiftUI

/*
 * The main view occupies the majority of the screen based on the router location
 */
struct MainView: View {

    // Properties
    private let viewManager: ViewManager?
    private let apiClient: ApiClient
    private let isDeviceSecured: Bool

    // The router
    @ObservedObject var viewRouter: ViewRouter

    /*
     * Receive properties from input
     */
    init (
        viewRouter: ViewRouter,
        viewManager: ViewManager,
        apiClient: ApiClient,
        isDeviceSecured: Bool) {

        self.viewRouter = viewRouter
        self.viewManager = viewManager
        self.apiClient = apiClient
        self.isDeviceSecured = isDeviceSecured
    }

    /*
     * Return the current view's markup, which depends on where we have navigated to
     */
    var body: some View {

        VStack {

            if !self.isDeviceSecured {

                // If security preconditions are not met then move to a device view
                DeviceNotSecuredView()

            } else if self.viewRouter.currentViewType == TransactionsView.Type.self {

                // Render the transactions view
                TransactionsView(
                    viewRouter: viewRouter,
                    viewManager: viewManager!,
                    apiClient: self.apiClient)

            } else if self.viewRouter.currentViewType == LoginRequiredView.Type.self {

                // Render the login required view
                LoginRequiredView()

            } else {

                // Render the companies view by default
                CompaniesView(
                    viewRouter: viewRouter,
                    viewManager: viewManager!,
                    apiClient: self.apiClient)
            }
        }
    }
}
