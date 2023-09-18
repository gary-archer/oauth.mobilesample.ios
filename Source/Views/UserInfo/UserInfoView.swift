import SwiftUI

/*
 * The user info view
 */
struct UserInfoView: View {

    @EnvironmentObject private var eventBus: EventBus
    @ObservedObject private var model: UserInfoViewModel

    init (model: UserInfoViewModel) {
        self.model = model
    }

    /*
     * Render user info details based on state
     */
    var body: some View {

        return VStack {

            // Render user info if it exists
            Text(self.model.getUserName())
                .font(.system(size: 14))

            // Render errors getting data when applicable
            ErrorSummaryView(
                containingViewName: "userinfo",
                hyperlinkText: "Problem Encountered",
                dialogTitle: "User Info Error",
                padding: EdgeInsets(top: -10, leading: 0, bottom: 0, trailing: 0))
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
        let options = ViewLoadOptions(forceReload: true, causeError: event.causeError)
        self.loadData(options: options)
    }

    /*
     * Ask the model to call the API to get data
     */
    private func loadData(options: ViewLoadOptions? = nil) {

        // Clear error state before calling the API and handle errors afterwards if there is failure
        self.eventBus.sendSetErrorEvent(containingViewName: "userinfo", error: nil)
        let onError: (UIError) -> Void = { error in
            self.eventBus.sendSetErrorEvent(containingViewName: "userinfo", error: error)
        }

        // Ask the model to call the API and update its state, which is then published to update the view
        self.model.callApi(options: options, onError: onError)
    }
}
