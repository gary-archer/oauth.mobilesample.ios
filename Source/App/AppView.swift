// If the login was cancelled, move to the login required view
import SwiftUI
import AppAuth
import SwiftCoroutine

/*
 * The main application view composes other views
 */
struct AppView: View {

    // External objects
    @ObservedObject var model: AppViewModel
    @EnvironmentObject var orientationHandler: OrientationHandler
    @EnvironmentObject var dataReloadHandler: DataReloadHandler

    // Properties
    private let mainWindow: UIWindow
    private let viewManager: ViewManager?
    private var viewRouter: ViewRouter

    /*
     * Initialise properties that we can set here
     */
    init(window: UIWindow, viewRouter: ViewRouter) {

        // Store window related objects
        self.mainWindow = window
        self.viewRouter = viewRouter
        self.viewManager = ViewManager()

        // Create the model, which manages mutable state
        self.model = AppViewModel()
    }

    /*
     * Render the application's tree of views
     */
    var body: some View {

        return VStack {

            // Display the title row including user info
            TitleView(
                apiClient: self.model.apiClient,
                viewManager: self.viewManager,
                shouldLoadUserInfo:
                    self.model.isInitialised &&
                    self.model.isDeviceSecured &&
                    !self.isInLoginRequired())

            // Next display the header buttons view
            HeaderButtonsView(
                sessionButtonsEnabled: self.model.isDataLoaded,
                onHome: self.onHome,
                onReloadData: self.onReloadData,
                onExpireAccessToken: self.onExpireAccessToken,
                onExpireRefreshToken: self.onExpireRefreshToken,
                onLogout: self.onLogout)
                    .padding(.bottom)

            // Display errors if applicable
            if self.model.error != nil {

                ErrorSummaryView(
                    hyperlinkText: "Application Problem Encountered",
                    dialogTitle: "Application Error",
                    error: self.model.error!)
                        .padding(.bottom)
            }

            // Render additional details once we've initialised the app
            if self.model.isInitialised {

                // Render the API session id
                SessionView(
                    apiClient: self.model.apiClient!,
                    isVisible: self.model.isDeviceSecured && self.model.authenticator!.isLoggedIn())
                        .padding(.bottom)

                // Render the main view depending on the router location
                MainView(
                    viewRouter: self.viewRouter,
                    viewManager: self.viewManager!,
                    apiClient: self.model.apiClient!,
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

            // Initialise the model, which manages mutable data
            try self.model.initialise()

            // Initialise the view manager
            self.viewManager!.initialise(
                onLoadStateChanged: self.onLoadStateChanged,
                onLoginRequired: self.onLoginRequired)
            self.viewManager!.setViewCount(count: 2)

        } catch {

            // Output error details
            let uiError = ErrorHandler.fromException(error: error)
            self.model.error = uiError
        }
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

            // Recheck device security if required
            if !self.model.isDeviceSecured {
                self.model.isDeviceSecured = DeviceSecurity.isDeviceSecured()
            }

            // Move to the home view
            self.viewRouter.currentViewType = CompaniesView.Type.self
            self.viewRouter.params = []

            // If there is an error loading data from the API then force a reload
            if self.model.authenticator!.isLoggedIn() && !self.model.isDataLoaded {
                self.onReloadData(causeError: false)
            }
        }
    }

    /*
     * Handle reload data button clicks by publishing the reload event
     */
    private func onReloadData(causeError: Bool) {
        self.viewManager!.setViewCount(count: 2)
        self.dataReloadHandler.sendReloadEvent(causeError: causeError)
    }

    /*
     * Update session button state while the main view loads
     */
    private func onLoadStateChanged(loaded: Bool) {
        self.model.isDataLoaded = loaded
    }

    /*
     * Start a login redirect when the view manager informs us that a permanent 401 has occurred
     */
    private func onLoginRequired() {
        self.onLogin()
    }

    /*
     * The login entry point
     */
    private func onLogin() {

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {

                // Ask the authenticator to do the OAuth work
                try self.model.authenticator!.login(viewController: self.mainWindow.rootViewController!)
                    .await()

                // Reload data after signing in
                self.onReloadData(causeError: false)

            } catch {

                let uiError = ErrorHandler.fromException(error: error)
                if uiError.errorCode == ErrorCodes.loginCancelled {

                    // If the login was cancelled, move to the login required view
                    self.viewRouter.currentViewType = LoginRequiredView.Type.self
                    self.viewRouter.params = []

                } else {

                    // Otherwise render the error in the UI
                    self.model.error = uiError
                }
            }
        }
    }

    /*
     * The logout entry point
     */
    private func onLogout() {

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {
                // Ask the authenticator to do the OAuth work
                try self.model.authenticator!.logout(viewController: self.mainWindow.rootViewController!)
                    .await()

                // Move to the login required view and update UI state
                self.viewRouter.currentViewType = LoginRequiredView.Type.self
                self.viewRouter.params = []
                self.model.isDataLoaded = false

            } catch {

                // On error, only output logout errors to the MacOS console rather than impacting the end user
                let uiError = ErrorHandler.fromException(error: error)
                ErrorConsoleReporter.output(error: uiError)

                // Move to the login required view and update UI state
                self.viewRouter.currentViewType = LoginRequiredView.Type.self
                self.viewRouter.params = []
                self.model.isDataLoaded = false
            }
        }
    }

    /*
     * Return true if our location is the login required view
     */
    private func isInLoginRequired() -> Bool {
        return self.viewRouter.currentViewType == LoginRequiredView.Type.self
    }

    /*
     * Make the access token act expired
     */
    private func onExpireAccessToken() {
        self.model.authenticator!.expireAccessToken()
    }

    /*
     * Make the refresh token act expired
     */
    private func onExpireRefreshToken() {
        self.model.authenticator!.expireRefreshToken()
    }
}
