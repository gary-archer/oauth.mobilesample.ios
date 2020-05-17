// If the login was cancelled, move to the login required view
import SwiftUI
import AppAuth

/*
 * The main application view composes other views
 */
struct AppView: View {

    // External objects
    @ObservedObject var model: AppViewModel
    @EnvironmentObject var orientationHandler: OrientationHandler
    @EnvironmentObject var dataReloadHandler: DataReloadHandler

    // Navigation properties
    private var viewRouter: ViewRouter

    /*
     * Initialise properties that we can safely set here
     */
    init(window: UIWindow, viewRouter: ViewRouter) {
        self.viewRouter = viewRouter
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
                viewManager: self.model.viewManager,
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
                    viewManager: self.model.viewManager!,
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
            try self.model.initialise(onLoginRequired: self.onLoginRequired)

            // Set navigation callbacks
            self.viewRouter.handleOAuthDeepLink = self.handleOAuthDeepLink
            self.viewRouter.onDeepLinkCompleted = self.onDeepLinkCompleted

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
            return
        }

        // If we have prompted the user to open settings and click home, update the model's flag
        if !self.model.isDeviceSecured {
            self.model.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        }

        // Move to the home view
        self.viewRouter.changeMainView(newViewType: CompaniesView.Type.self, newViewParams: [])

        // If there is an error loading data from the API then force a reload
        if self.model.authenticator!.isLoggedIn() && !self.model.isDataLoaded {
            self.onReloadData(causeError: false)
        }
    }

    /*
     * Handle reload data button clicks by publishing the reload event
     */
    private func onReloadData(causeError: Bool) {

        self.model.viewManager!.setViewCount(count: 2)
        self.dataReloadHandler.sendReloadEvent(causeError: causeError)
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

        // Handle cancelled logins by moving to login required
        let onError: (UIError) -> Void = { uiError in
            if uiError.errorCode == ErrorCodes.redirectCancelled {
                self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])
            }
            self.viewRouter.isTopMost = true
        }

        // Indicate that we are no longer top most then get the model to do logic of the login
        self.viewRouter.isTopMost = true
        self.model.login(
            sceneDelegate: self.getSceneDelegate()!,
            onSuccess: onSuccess,
            onError: onError)
    }

    /*
     * Process any deep link notifications, including login / logout responses
     */
    func handleOAuthDeepLink(url: URL) -> Bool {

        return self.model.handleOAuthDeepLink(
            url: url,
            sceneDelegate: self.getSceneDelegate()!)
    }

    /*
     * The logout entry point
     */
    private func onLogout() {

        // Do post logout processing on success
        let onSuccess = {
            self.postLogout()
        }

        // If there is a logout error then we don't impact the user
        let onError: (UIError) -> Void = { uiError in
            if uiError.errorCode != ErrorCodes.redirectCancelled {
                ErrorConsoleReporter.output(error: uiError)
            }
            self.postLogout()
        }

        // Indicate that we are no longer top most then get the model to do logic of the logout
        self.viewRouter.isTopMost = true
        self.model.logout(
            sceneDelegate: self.getSceneDelegate()!,
            onSuccess: onSuccess,
            onError: onError)
    }

    /*
     * Move to the login required view and update UI state
     */
    private func postLogout() {

        self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])
        self.model.isDataLoaded = false
        self.viewRouter.isTopMost = true
    }

    /*
     * Post deep linking actions
     */
    func onDeepLinkCompleted(isSameView: Bool) {

        // Handle an issue deep linking to transactions for company 1 when transactions for company 2 are active
        // In this case the onAppear function is not called within the transactions view so we need to force an update
        // https://github.com/onmyway133/blog/issues/468
        if isSameView {
            self.onReloadData(causeError: false)
        }
    }

    /*
     * A helper method to get the scene delegate, on which the login response is received
     */
    private func getSceneDelegate() -> SceneDelegate? {

        let scene = UIApplication.shared.connectedScenes.first
        return scene!.delegate as? SceneDelegate
    }
}
