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
            TitleView(userInfoViewModel: self.model.getUserInfoViewModel())

            // Next display the header buttons view
            HeaderButtonsView(
                onHome: self.onHome,
                onReloadData: self.model.triggerDataReload,
                onExpireAccessToken: self.model.expireAccessToken,
                onExpireRefreshToken: self.model.expireRefreshToken,
                onLogout: self.onLogout)

            // Display application level errors when applicable
            if self.model.error != nil {
                ErrorSummaryView(
                    error: self.model.error!,
                    hyperlinkText: "main_error_hyperlink",
                    dialogTitle: "main_error_dialogtitle",
                    padding: EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
            }

            // Next display the session view
            SessionView(isVisible: self.model.isLoaded, sessionId: self.model.getSessionId())

            // Render the main view based on the user's current location
            MainView(
                viewRouter: self.viewRouter,
                companiesViewModel: self.model.getCompaniesViewModel(),
                transactionsViewModel: self.model.getTransactionsViewModel(),
                isDeviceSecured: self.model.isDeviceSecured)

            // Fill up the remainder of the view if needed
            Spacer()
        }
        .onAppear(perform: self.onInitialize)
        .onReceive(self.model.eventBus.loginRequiredTopic, perform: {_ in
            self.onLoginRequired()
        })
    }

    /*
     * Initialize the model
     */
    private func onInitialize() {
        self.model.initialize(onComplete: self.onInitializeComplete)
    }

    /*
     * Move to the initial main view once the view model is initialized
     */
    private func onInitializeComplete() {

        if self.model.deepLinkStartupUrl != nil {

            // Apply the deep link startup URL if supplied
            self.viewRouter.handleDeepLink(url: self.model.deepLinkStartupUrl!)

        } else {

            // Otherwise change to the default view
            self.viewRouter.navigateToPath(
                newViewType: CompaniesView.Type.self,
                newViewParams: []
            )
        }
    }

    /*
     * Navigate to the login required view when the view model coordinator raises the event
     */
    private func onLoginRequired() {
        self.viewRouter.navigateToLoginRequired()
    }

    /*
     * Start the work of the login redirect
     */
    private func onStartLogin() {

        // Prevent re-entrancy
        if !self.viewRouter.isTopMost {
            return
        }

        // Indicate that the ASWebAuthenticationSession window is now topmost
        self.viewRouter.isTopMost = false

        // Handle completion
        let onComplete: (Bool) -> Void = { isCancelled in

            // Indicate that this view is now topmost
            self.viewRouter.isTopMost = true

            if isCancelled {

                // Move to login required if the login was cancelled
                self.viewRouter.navigateToLoginRequired()

            } else if self.model.error == nil {

                // Then move to the post login location
                self.viewRouter.navigateAfterLogin()
            }
        }

        // Trigger the login
        self.model.login(viewController: self.getHostingViewController(), onComplete: onComplete)
    }

    /*
     * The logout entry point
     */
    private func onLogout() {

        // Prevent re-entrancy
        if !self.viewRouter.isTopMost {
            return
        }

        // Indicate that the ASWebAuthenticationSession window is now topmost
        self.viewRouter.isTopMost = false

        // Handle completion
        let onComplete: () -> Void = {
            self.viewRouter.isTopMost = true
            self.viewRouter.navigateToLoggedOut()
        }

        // Trigger the logout
        self.model.logout(viewController: self.getHostingViewController(), onComplete: onComplete)
    }

    /*
     * The home button either initiates a login or navigates home
     */
    private func onHome() {

        // Reset the main view's own error if required
        self.model.error = nil

        // If there is a startup error then retry initializing
        if !self.model.isLoaded {
            self.onInitialize()
            return
        }

        // If we have prompted the user to open settings and click home, update the model's flag
        if !self.model.isDeviceSecured {
            self.model.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        }

        // Inspect the current view
        if !self.model.isLoggedIn() {

            // Start a new login if we are not authenticated
            self.onStartLogin()

        } else {

            // Navigate home unless we are already there
            if self.viewRouter.activeViewType != CompaniesView.Type.self {
                self.viewRouter.navigateToPath(newViewType: CompaniesView.Type.self, newViewParams: [])
            }

            // Force a data reload if recovering from errors
            if model.viewModelCoordinator.hasErrors() {
                self.model.triggerDataReload(causeError: false)
            }
        }
    }

    /*
     * A helper method to get the root view controller
     */
    private func getHostingViewController() -> UIViewController {

        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene!.keyWindow!.rootViewController!
    }
}
