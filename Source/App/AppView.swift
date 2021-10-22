import SwiftUI
import AppAuth

/*
 * The main application view composes other views
 */
struct AppView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @ObservedObject private var model: AppViewModel
    private var viewRouter: ViewRouter

    /*
     * Initialise properties that we can safely set here
     */
    init(model: AppViewModel, viewRouter: ViewRouter) {
        self.model = model
        self.viewRouter = viewRouter
    }

    /*
     * Render the application's tree of views
     */
    var body: some View {

        return VStack {

            // Display the title row including user info
            TitleView(
                userInfoViewModel: self.model.getUserInfoViewModel(),
                shouldLoadUserInfo: self.model.isDeviceSecured && !self.viewRouter.isInLoginRequired()
            )

            // Next display the header buttons view
            HeaderButtonsView(
                sessionButtonsEnabled: self.model.isMainViewLoaded,
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

            // Render the main view based on the user's current location
            MainView(
                viewRouter: self.viewRouter,
                companiesViewModel: self.model.getCompaniesViewModel(),
                transactionsViewModel: self.model.getTransactionsViewModel(),
                isDeviceSecured: self.model.isDeviceSecured)

            // Fill up the remainder of the view if needed
            Spacer()
        }
        .onReceive(self.model.eventPublisher.dataStatusTopic, perform: {data in
            self.handleDataStatusUpdate(event: data)
        })
        .onReceive(self.model.eventPublisher.loginRequiredTopic, perform: {_ in
            self.onLoginRequired()
        })
    }

    private func handleDataStatusUpdate(event: DataStatusEvent) {
        self.model.isMainViewLoaded = event.loaded
    }

    /*
     * Start a login redirect when the view manager informs us that a permanent 401 has occurred
     */
    private func onLoginRequired() {

        // Prevent re-entrancy
        if !self.viewRouter.isTopMost {
            return
        }

        // Reload data after signing in
        let onSuccess = {
            self.viewRouter.isTopMost = true
            self.onReloadData(causeError: false)
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

        // Indicate that we are no longer top most, then get the model class to run the login
        self.viewRouter.isTopMost = false

        // Use a small delay to work around an intermittent issue if we start the app via a shortcut or deep link
        // 'The UIWindowScene for the returned window was not in the foreground active state'
        // https://github.com/openid/AppAuth-iOS/issues/498
        let secondsToDelay = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsToDelay) {

            self.model.login(
                viewController: self.getHostingViewController(),
                onSuccess: onSuccess,
                onError: onError)
        }
    }

    /*
     * The logout entry point
     */
    private func onLogout() {

        // Prevent re-entrancy
        if !self.viewRouter.isTopMost {
            return
        }

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

        // Indicate that we are no longer top most then get the model to run the logout
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

        self.viewRouter.isTopMost = true
        self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])
        self.model.onLogout()
    }

    /*
     * Handle home button clicks
     */
    private func onHome() {

        // If we have prompted the user to open settings and click home, update the model's flag
        if !self.model.isDeviceSecured {
            self.model.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        }

        // Move to the home view
        if self.viewRouter.isInHomeView() {

            // Force the main view to reload
            self.model.eventPublisher.sendReloadMainViewEvent(causeError: false)

        } else {

            // Otherwise move to the home view
            self.viewRouter.changeMainView(newViewType: CompaniesView.Type.self, newViewParams: [])
        }
    }

    /*
     * Handle reload data button clicks by publishing reload events
     */
    private func onReloadData(causeError: Bool) {

        self.model.apiViewEvents.clearState()
        self.model.eventPublisher.sendReloadMainViewEvent(causeError: causeError)
        self.model.eventPublisher.sendReloadUserInfoEvent(causeError: causeError)
    }

    /*
     * A helper method to get the scene delegate, on which the login response is received
     */
    private func getHostingViewController() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
}
