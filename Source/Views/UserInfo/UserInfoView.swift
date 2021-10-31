import SwiftUI

/*
 * The user info view
 */
struct UserInfoView: View {

    @EnvironmentObject private var eventBus: EventBus
    @ObservedObject private var model: UserInfoViewModel
    private let viewRouter: ViewRouter
    private let isDeviceSecured: Bool

    init (model: UserInfoViewModel, viewRouter: ViewRouter, isDeviceSecured: Bool) {
        self.model = model
        self.viewRouter = viewRouter
        self.isDeviceSecured = isDeviceSecured
    }

    /*
     * Render user info details based on state
     */
    var body: some View {

        return VStack {

            if self.model.error != nil && self.model.error!.errorCode != ErrorCodes.loginRequired {

                // Render error details if they exist
                ErrorSummaryView(
                    hyperlinkText: "Problem Encountered",
                    dialogTitle: "User Info Error",
                    error: self.model.error!)

            } else {

                // Render user info if it exists
                Text(self.model.getUserName())
                    .font(.system(size: 14))
            }
        }
        .onReceive(self.eventBus.navigatedTopic, perform: {data in
            self.handleNavigateEvent(event: data)
        })
        .onReceive(self.eventBus.reloadUserInfoTopic, perform: { data in
            self.handleReloadEvent(event: data)
        })
    }

    /*
     * Load data when the main view is navigated to
     */
    private func handleNavigateEvent(event: NavigatedEvent) {

        if event.isMainView {

            // Load user data the first time
            self.loadData()

        } else {

            // Clear data when in the logged out view
            self.model.clearData()
        }
   }

    /*
     * Handle reload events
     */
    private func handleReloadEvent(event: ReloadUserInfoEvent) {
        self.loadData(reload: true, causeError: event.causeError)
    }

    /*
     * Ask the model to call the API to get data
     */
    private func loadData(reload: Bool = false, causeError: Bool = false) {

        let options = UserInfoLoadOptions(
            isDeviceSecured: self.isDeviceSecured,
            reload: reload,
            isInLoggedOutView: self.viewRouter.isInLoginRequired(),
            causeError: causeError)

        self.model.callApi(options: options)
    }
}
