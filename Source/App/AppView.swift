import SwiftUI
import AppAuth
import OSLog

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
                onReloadData: self.model.reloadData,
                onExpireAccessToken: self.model.onExpireAccessToken,
                onExpireRefreshToken: self.model.onExpireRefreshToken,
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
     * If there is a startup deep link then we wait for onOpenURL to process it
     * Otherwise, when the app starts normally, change to the default view here
     */
    private func onInitializeComplete() {

        if SampleSceneDelegate.startupDeepLinkUrl == nil {

            self.viewRouter.changeMainView(
                newViewType: CompaniesView.Type.self,
                newViewParams: []
            )
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

        // Indicate that the ASWebAuthenticationSession window is now topmost
        self.viewRouter.isTopMost = false

        // Handle completion
        let onComplete: (Bool) -> Void = { isCancelled in

            // Indicate that this view is now topmost
            self.viewRouter.isTopMost = true

            if isCancelled {

                // Move to login required if the login was cancelled
                self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])

            } else if self.model.error == nil {

                if self.viewRouter.currentViewType == LoginRequiredView.Type.self {

                    // If the user logs in from the login required view, then navigate home
                    self.viewRouter.changeMainView(newViewType: CompaniesView.Type.self, newViewParams: [])

                } else {

                    // Otherwise we are handling expiry so reload data in the current view
                    self.model.reloadData(causeError: false)
                }
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
            self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])
        }

        // Trigger the logout
        self.model.logout(viewController: self.getHostingViewController(), onComplete: onComplete)
    }

    /*
     * Handle home button clicks
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
        if self.viewRouter.currentViewType == LoginRequiredView.Type.self {

            // Start a new login when logged out
            self.onLoginRequired()

        } else {

            // Otherwise move to the home view unless already there
            if self.viewRouter.currentViewType != CompaniesView.Type.self {
                self.viewRouter.changeMainView(newViewType: CompaniesView.Type.self, newViewParams: [])
            }

            // Also reload user info if we are recovering from an error
            if model.viewModelCoordinator.hasErrors() {
                self.model.reloadDataOnError()
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
