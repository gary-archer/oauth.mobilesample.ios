import SwiftUI

/*
 * The main view occupies the majority of the screen based on the router location
 */
struct MainView: View {

    @ObservedObject private var viewRouter: ViewRouter
    @ObservedObject private var companiesViewModel: CompaniesViewModel
    @ObservedObject private var transactionsViewModel: TransactionsViewModel
    private let isLoaded: Bool
    private let isDeviceSecured: Bool

    init (
        viewRouter: ViewRouter,
        companiesViewModel: CompaniesViewModel,
        transactionsViewModel: TransactionsViewModel,
        isLoaded: Bool,
        isDeviceSecured: Bool) {

        self.viewRouter = viewRouter
        self.companiesViewModel = companiesViewModel
        self.transactionsViewModel = transactionsViewModel
        self.isLoaded = isLoaded
        self.isDeviceSecured = isDeviceSecured
    }

    /*
     * Return the UI elements, depending on the location navigated to
     */
    var body: some View {

        return VStack {

            if !self.isLoaded {
                
                // Render an empty main view if the app is not loaded yet
            }
            else if !self.isDeviceSecured {

                // We require a secured device so move here if prerequisites are not met
                DeviceNotSecuredView()

            } else if self.viewRouter.currentViewType == TransactionsView.Type.self {

                // Render the transactions view
                TransactionsView(model: self.transactionsViewModel, viewRouter: self.viewRouter)

            } else if self.viewRouter.currentViewType == LoginRequiredView.Type.self {

                // Render the login required view
                LoginRequiredView()

            } else {

                // Render the companies view by default
                CompaniesView(model: self.companiesViewModel, viewRouter: self.viewRouter)
            }
        }
    }
}
