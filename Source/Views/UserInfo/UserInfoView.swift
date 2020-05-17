import SwiftUI

/*
 * The user info view
 */
struct UserInfoView: View {

    // External objects
    @ObservedObject var model: UserInfoViewModel
    @EnvironmentObject var dataReloadHandler: DataReloadHandler

    // Properties
    private let shouldLoad: Bool

    /*
     * Initialise from input
     */
    init (apiClient: ApiClient, viewManager: ViewManager, shouldLoad: Bool) {
        self.model = UserInfoViewModel(viewManager: viewManager, apiClient: apiClient)
        self.shouldLoad = shouldLoad
    }

    /*
     * Render user info details based on state
     */
    var body: some View {

        VStack {

            // Render error details if they exist
            if self.model.error != nil && self.model.error!.errorCode != ErrorCodes.loginRequired {
                ErrorSummaryView(
                    hyperlinkText: "Problem Encountered",
                    dialogTitle: "User Info Error",
                    error: self.model.error!)
                        .padding(.top)
            }

            // Render user info if it exists, and register for the receive data event
            Text(self.model.getUserName(shouldLoad: self.shouldLoad))
                .font(.system(size: 14))
                .onAppear(perform: self.initialLoad)
                .onReceive(self.dataReloadHandler.objectWillChange, perform: { causeError in
                    self.loadData(causeError: causeError)
                })
        }
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
