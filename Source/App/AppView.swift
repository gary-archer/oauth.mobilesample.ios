import SwiftUI
import AppAuth

/*
 * The main application view composes other views
 */
struct AppView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @ObservedObject private var model: AppViewModel
    private var viewRouter: ViewRouter
    private var apiViewEvents: ApiViewEvents

    /*
     * Initialise properties that we can safely set here
     */
    init(model: AppViewModel, viewRouter: ViewRouter, apiViewEvents: ApiViewEvents) {
        self.model = model
        self.viewRouter = viewRouter
        self.apiViewEvents = apiViewEvents
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
            // Initialise the model, which loads configuration and creates global objects
            try self.model.initialise(apiViewEvents: self.apiViewEvents)

            // Initialise the events helper object with the names of view areas that call the Web API
            self.apiViewEvents.initialise(
                onLoginRequiredAction: self.onLoginRequired,
                onMainLoadStateChanged: self.model.onMainLoadStateChanged
            )
            self.apiViewEvents.addView(name: ApiViewNames.Main)
            self.apiViewEvents.addView(name: ApiViewNames.UserInfo)

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

        // If there is a startup error then reinitialise the app
        if !self.model.isInitialised {
            self.initialiseApp()
        }

        if self.model.isInitialised {

            // If we have prompted the user to open settings and click home, update the model's flag
            if !self.model.isDeviceSecured {
                self.model.isDeviceSecured = DeviceSecurity.isDeviceSecured()
            }

            // Move to the home view
            if self.viewRouter.isInHomeView() {

                // Force the home view to reload
                self.model.dataReloadHandler.sendReloadEvent(viewName: ApiViewNames.Main, causeError: false)

            } else {

                // Otherwise move to the home view
                self.viewRouter.changeMainView(newViewType: CompaniesView.Type.self, newViewParams: [])
            }
        }
    }

    /*
     * Handle reload data button clicks by publishing reload events
     */
    private func onReloadData(causeError: Bool) {

        self.apiViewEvents.clearState()
        self.model.dataReloadHandler.sendReloadEvent(viewName: ApiViewNames.Main, causeError: causeError)
        self.model.dataReloadHandler.sendReloadEvent(viewName: ApiViewNames.UserInfo, causeError: causeError)
    }

    /*
     * A helper method to get the scene delegate, on which the login response is received
     */
    private func getHostingViewController() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
}
