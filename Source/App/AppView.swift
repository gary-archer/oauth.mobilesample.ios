// If the login was cancelled, move to the login required view
import SwiftUI
import AppAuth
import SwiftCoroutine

/*
 * The main application view composes other views
 */
struct AppView: View {

    // External objects
    @ObservedObject var model: AppData
    @EnvironmentObject var reloadPublisher: ReloadPublisher

    // Properties
    private let mainWindow: UIWindow
    private var viewRouter: ViewRouter

    // This view's state
    @State private var error: UIError?
    @State private var sessionButtonsEnabled = false
    @State private var showApiSessionId = false

    /*
     * Initialise properties that we can set here
     */
    init(window: UIWindow, viewRouter: ViewRouter) {
        self.mainWindow = window
        self.viewRouter = viewRouter
        self.model = AppData()
    }

    /*
     * Render the application's tree of views
     */
    var body: some View {

        VStack {

            // Display the title row including user info
            TitleView(
                viewManager: self.model.viewManager,
                apiClient: self.model.apiClient,
                loadUserInfo: self.model.isInitialised)

            // Next display the header buttons view
            HeaderButtonsView(
                viewRouter: self.viewRouter,
                sessionButtonsEnabled: self.sessionButtonsEnabled,
                onHome: self.onHome,
                onReloadData: self.onReloadData,
                onExpireAccessToken: self.expireAccessToken,
                onExpireRefreshToken: self.expireRefreshToken,
                onLogout: self.onLogout)
                    .padding(.bottom)

            // Display errors if applicable
            if self.error != nil {
                ErrorSummaryView(
                    hyperlinkText: "Problem Encountered in Application",
                    dialogTitle: "Application Error",
                    error: self.error!)
                        .padding(.bottom)
            }

            // Render additional details once we've started up successfully
            if self.model.isInitialised {

                // Render the API session id
                SessionView(
                    apiClient: self.model.apiClient!,
                    isVisible: self.showApiSessionId)
                        .padding(.bottom)

                // Render the main view depending on the router location
                CurrentRouterView(
                    viewRouter: self.viewRouter,
                    viewManager: self.model.viewManager!,
                    apiClient: self.model.apiClient!)
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
            // Initialise the model, which manages mutable properties
            // Note that Swift does not allow us to change properties in this struct after init is called
            try self.model.initialise(
                onLoadStateChanged: self.onLoadStateChanged,
                onLoginRequired: self.onLoginRequired)

            // Show the session id unless we need to log in
            self.showApiSessionId = self.model.authenticator!.isLoggedIn()

        } catch {

            // Output error details
            let uiError = ErrorHandler().fromException(error: error)
            self.error = uiError
        }
    }

    /*
     * Handle home button clicks
     */
    private func onHome() {

        // If there is an error then reinitialise the app to force all fragments to reload
        if !self.model.isInitialised {
            self.initialiseApp()
        }

        if self.model.isInitialised {

            // If there is a view error, force a reload to correct it
            if self.model.viewManager!.hasError() {
                self.onReloadData()
            }

            // Move to the home view
            self.viewRouter.currentViewType = CompaniesView.Type.self
            self.viewRouter.params = []
        }
    }

    /*
     * Handle reload data button clicks by publishing the reload event
     */
    private func onReloadData() {
        self.reloadPublisher.reload()
    }

    /*
     * Update session button state while the main view loads
     */
    private func onLoadStateChanged(loaded: Bool) {
        self.sessionButtonsEnabled = loaded
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

                // Show the API session id once complete
                self.showApiSessionId = true

                // Reload data after signing in
                self.onReloadData()

            } catch {

                let uiError = ErrorHandler().fromException(error: error)
                if uiError.errorCode == ErrorCodes.loginCancelled {

                    // If the login was cancelled, move to the login required view
                    self.viewRouter.currentViewType = LoginRequiredView.Type.self
                    self.viewRouter.params = []
                    self.showApiSessionId = false

                } else {

                    // Otherwise render the error in the UI
                    self.error = uiError
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

                // Move to the login required view after logging out
                self.viewRouter.currentViewType = LoginRequiredView.Type.self
                self.viewRouter.params = []

                // Also update UI state
                self.sessionButtonsEnabled = false
                self.showApiSessionId = false

            } catch {

                let uiError = ErrorHandler().fromException(error: error)
                if uiError.errorCode == ErrorCodes.loginCancelled {

                    // Move to login required and update UI state
                    self.viewRouter.currentViewType = LoginRequiredView.Type.self
                    self.viewRouter.params = []
                    self.sessionButtonsEnabled = false
                    self.showApiSessionId = false

                } else {

                    // Otherwise render the error in the UI
                    self.error = uiError
                }
            }
        }
    }

    /*
     * Make the access token act expired
     */
    private func expireAccessToken() {
        self.model.authenticator?.expireAccessToken()
    }

    /*
     * Make the refresh token act expired
     */
    private func expireRefreshToken() {
        self.model.authenticator?.expireRefreshToken()
    }
}
