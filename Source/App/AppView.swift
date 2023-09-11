import SwiftUI
import AppAuth

/*
 * The main application view composes other views
 */
struct AppView: View {

    @EnvironmentObject private var eventBus: EventBus
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
                onReloadData: self.onReloadData,
                onExpireAccessToken: self.model.onExpireAccessToken,
                onExpireRefreshToken: self.model.onExpireRefreshToken,
                onLogout: self.onLogout)

            // Display application level errors when applicable
            ErrorSummaryView(
                containingViewName: "main",
                hyperlinkText: "Application Problem Encountered",
                dialogTitle: "Application Error",
                padding: EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))

            // Next display the session view
            SessionView(sessionId: self.model.getSessionId())

            // Render the main view based on the user's current location
            MainView(
                viewRouter: self.viewRouter,
                companiesViewModel: self.model.getCompaniesViewModel(),
                transactionsViewModel: self.model.getTransactionsViewModel(),
                isDeviceSecured: self.model.isDeviceSecured)

            // Fill up the remainder of the view if needed
            Spacer()
        }
        .onReceive(self.eventBus.loginRequiredTopic, perform: {_ in
            self.onLoginRequired()
        })
    }

    /*
     * Start a login redirect when the view manager informs us that a permanent 401 has occurred
     */
    private func onLoginRequired() {

        // Prevent re-entrancy
        if !self.viewRouter.isTopMost {
            return
        }

        // Clear state and indicate that the ASWebAuthenticationSession window is now topmost
        self.eventBus.sendSetErrorEvent(containingViewName: "main", error: nil)
        self.viewRouter.isTopMost = false

        Task {

            do {
                // Do the OAuth work
                try await self.model.login(viewController: self.getHostingViewController())

                // Then update the user interface
                await MainActor.run {
                    self.viewRouter.isTopMost = true
                    self.onReloadData(causeError: false)
                }

            } catch {

                await MainActor.run {

                    self.viewRouter.isTopMost = true

                    let uiError = ErrorFactory.fromException(error: error)
                    if uiError.errorCode == ErrorCodes.redirectCancelled {

                        // Move to login required if the login was cancelled
                        self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])

                    } else {

                        // Report other error conditions
                        self.eventBus.sendSetErrorEvent(containingViewName: "main", error: uiError)
                    }
                }
            }
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

        // Indicate that the ASWebAuthenticationSession window is now topmost
        self.viewRouter.isTopMost = false

        Task {

            do {
                // Do the OAuth work
                try await self.model.logout(viewController: self.getHostingViewController())

                // Move to the logged out state
                await MainActor.run {
                    self.postLogout()
                }

            } catch {

                await MainActor.run {

                    // Report logout errors only to the console, and ignore cancellations
                    let uiError = ErrorFactory.fromException(error: error)
                    if uiError.errorCode != ErrorCodes.redirectCancelled {
                        ErrorConsoleReporter.output(error: uiError)
                    }

                    // Move to the logged out state
                    self.postLogout()
                }
            }
        }
    }

    /*
     * Move to the login required view and update UI state
     */
    private func postLogout() {

        self.viewRouter.isTopMost = true
        self.viewRouter.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])
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
            self.eventBus.sendReloadMainViewEvent(causeError: false)

        } else {

            // Otherwise move to the home view
            self.viewRouter.changeMainView(newViewType: CompaniesView.Type.self, newViewParams: [])
        }

        // Also reload user info if we are recovering from an error
        if model.apiViewEvents.hasLoadError() {
            self.eventBus.sendReloadUserInfoEvent(causeError: false)
        }
    }

    /*
     * Handle reload data button clicks by publishing reload events
     */
    private func onReloadData(causeError: Bool) {

        self.model.apiViewEvents.clearState()
        self.eventBus.sendReloadMainViewEvent(causeError: causeError)
        self.eventBus.sendReloadUserInfoEvent(causeError: causeError)
    }

    /*
     * A helper method to get the root view controller
     */
    private func getHostingViewController() -> UIViewController {

        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene!.keyWindow!.rootViewController!
    }
}
