import SwiftUI

/*
 * The user info view
 */
struct UserInfoView: View {

    @EnvironmentObject private var eventBus: EventBus
    @ObservedObject private var model: UserInfoViewModel
    private let shouldLoad: Bool

    init (model: UserInfoViewModel, shouldLoad: Bool) {
        self.model = model
        self.shouldLoad = shouldLoad
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
                Text(self.model.getUserName(shouldLoad: self.shouldLoad))
                    .font(.system(size: 14))
            }
        }
        .onAppear(perform: self.initialLoad)
        .onReceive(self.eventBus.reloadUserInfoTopic, perform: { data in
            self.handleReloadEvent(event: data)
        })
    }

    /*
     * Receive events
     */
    private func handleReloadEvent(event: ReloadUserInfoEvent) {
        self.loadData(causeError: event.causeError)
    }

    /*
     * Do the initial load
     */
    private func initialLoad() {
        self.loadData(causeError: false)
    }

    /*
     * Ask the model to call the API to get data
     */
    private func loadData(causeError: Bool) {
        let options = ApiRequestOptions(causeError: causeError)
        self.model.callApi(options: options, shouldLoad: self.shouldLoad)
    }
}
