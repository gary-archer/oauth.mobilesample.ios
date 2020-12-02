import SwiftUI
import AppAuth

/*
 * The main application view composes other views
 */
struct AppView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @ObservedObject private var model: AppViewModel
    private var viewRouter: ViewRouter
    private var viewManager: ViewManager

    /*
     * Initialise properties that we can safely set here
     */
    init(model: AppViewModel, viewRouter: ViewRouter, viewManager: ViewManager) {
        self.model = model
        self.viewRouter = viewRouter
        self.viewManager = viewManager
    }

    /*
     * Render the application's tree of views
     */
    var body: some View {

        return VStack {

            // Display the title row including user info
            TitleView(
                userInfoViewModel: self.model.userInfoViewModel,
                shouldLoadUserInfo:
                    self.model.isInitialised &&
                    self.model.isDeviceSecured &&
                    !self.viewRouter.isInLoginRequired()
            )

            // Next display the header buttons view
            HeaderButtonsView(
                sessionButtonsEnabled: self.model.isDataLoaded,
                onHome: self.onHome,
                onReloadData: self.onReloadData,
                onExpireAccessToken: self.model.onExpireAccessToken,
                onExpireRefreshToken: self.model.onExpireRefreshToken,
                onLogout: self.onLogout)
                    .padding(.bottom)

            // Display application level errors if applicable
            if self.model.error != nil {

                ErrorSummaryView(
                    hyperlinkText: "Application Problem Encountered",
                    dialogTitle: "Application Error",
                    error: self.model.error!)
                        .padding(.bottom)
            }

            // After we've initialised the app, rnder the main view based on the user's current location
            if self.model.isInitialised {

                MainView(
                    viewRouter: self.viewRouter,
                    companiesViewModel: self.model.companiesViewModel,
                    transactionsViewModel: self.model.transactionsViewModel,
                    isDeviceSecured: self.model.isDeviceSecured)
            }

            // Fill up the remainder of the view if needed
            Spacer()

        }
        .onAppear(perform: self.initialiseApp)
    }

    /*
     * The main startup logic occurs after the initial render
     */
    private func initialiseApp() {

        do {
            // Initialise the view manager
            self.viewManager.initialise(
                onLoadStateChanged: self.model.onLoadStateChanged,
                onLoginRequired: self.onLoginRequired)
            self.viewManager.setViewCount(count: 2)

            // Initialise the model, which loads configuration and creates global objects
            try self.model.initialise(viewManager: self.viewManager)

        } catch {

            // Render any error details
            let uiError = ErrorHandler.fromException(error: error)
            self.model.error = uiError
        }
    }

    /*
     * Start a login redirect when the view manager informs us that a permanent 401 has occurred
     */
    private func onLoginRequired() {

        // Reload data after signing in
        let onSuccess = {
            self.onReloadData(causeError: false)
            self.viewRouter.isTopMost = true
        }

        // Handle logout errors
        let onError: (UIError) -> Void = { uiError in

            if uiError.errorCode == ErrorCodes.redirectCancelled {

                // Move to login required if the login was cancelled
                self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])

            } else {

                // Report other error conditions
                self.model.error = uiError
            }

            self.viewRouter.isTopMost = true
        }

        // Indicate that we are no longer top most then get the model to do logic of the login
        self.viewRouter.isTopMost = false
        self.model.login(
            viewController: self.getHostingViewController(),
            onSuccess: onSuccess,
            onError: onError)
    }

    /*
     * The logout entry point
     */
    private func onLogout() {

        // Do post logout processing on success
        let onSuccess = {
            self.postLogout()
        }

        // If there is a logout error then we silently fail rather than impacting the user
        let onError: (UIError) -> Void = { uiError in
            if uiError.errorCode != ErrorCodes.redirectCancelled {
                ErrorConsoleReporter.output(error: uiError)
            }
            self.postLogout()
        }

        // Indicate that we are no longer top most then get the model to do logic of the logout
        self.viewRouter.isTopMost = false
        self.model.logout(
            viewController: self.getHostingViewController(),
            onSuccess: onSuccess,
            onError: onError)
    }

    /*
     * Move to the login required view and update UI state
     */
    private func postLogout() {

        self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])
        self.model.onLogout()
        self.viewRouter.isTopMost = true
    }

    /*
     * Handle home button clicks
     */
    private func onHome() {

        // If there is a startup error then reinitialise the app
        if !self.model.isInitialised {
            self.initialiseApp()
            return
        }

        // If we have prompted the user to open settings and click home, update the model's flag
        if !self.model.isDeviceSecured {
            self.model.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        }

        // Move to the home view
        if self.viewRouter.currentViewType != CompaniesView.Type.self {
            self.viewRouter.changeMainView(newViewType: CompaniesView.Type.self, newViewParams: [])
        }

        // If there is an error loading data from the API then force a reload
        if self.model.isLoggedIn() && !self.model.isDataLoaded {
            self.onReloadData(causeError: false)
        }
    }

    /*
     * Handle reload data button clicks by publishing the reload event
     */
    private func onReloadData(causeError: Bool) {

        self.viewManager.setViewCount(count: 2)
        self.model.dataReloadHandler.sendReloadEvent(causeError: causeError)
    }

    /*
     * A helper method to get the scene delegate, on which the login response is received
     */
    private func getHostingViewController() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
}
