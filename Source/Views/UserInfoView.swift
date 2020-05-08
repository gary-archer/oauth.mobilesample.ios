import SwiftUI

/*
 * The user info view
 */
struct UserInfoView: View {

    // External objects
    @EnvironmentObject var dataReloadHandler: DataReloadHandler

    // Properties
    private let apiClient: ApiClient?
    private let viewManager: ViewManager
    private let shouldLoad: Bool

    // This view's state
    @State private var userInfo: UserInfoClaims?
    @State private var error: UIError?

    /*
     * Initialise from input
     */
    init (apiClient: ApiClient?, viewManager: ViewManager, shouldLoad: Bool) {
        self.apiClient = apiClient
        self.viewManager = viewManager
        self.shouldLoad = shouldLoad
    }

    /*
     * Render user info details based on state
     */
    var body: some View {

        VStack {

            // Render error details if they exist
            if self.error != nil && self.error!.errorCode != ErrorCodes.loginRequired {

                ErrorSummaryView(
                    hyperlinkText: "Problem Encountered",
                    dialogTitle: "User Info Error",
                    error: self.error!)
                        .padding(.top)

            }

            // Render user info if it exists, and register for the receive data event
            Text(self.getUserName())
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
     * Call the API to get data
     */
    private func loadData(causeError: Bool) {

        // Check preconditions
        if apiClient == nil || !self.shouldLoad {
            self.viewManager.onViewLoaded()
            return
        }

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {

                // Initialise for this request
                self.error = nil
                let options = ApiRequestOptions(causeError: false)

                // Make the API call on a background thread
                self.viewManager.onViewLoading()
                try DispatchQueue.global().await {
                    self.userInfo = try self.apiClient!.getUserInfo(options: options).await()
                }
                self.viewManager.onViewLoaded()

            } catch {

                // Report errors
                let uiError = ErrorHandler.fromException(error: error)
                self.viewManager.onViewLoadFailed(error: uiError)
                self.error = uiError
            }
        }
    }

    /*
     * Return the user name to display
     */
    private func getUserName() -> String {

        if !self.shouldLoad || self.userInfo == nil {
            return ""
        }

        return "\(self.userInfo!.givenName) \(self.userInfo!.familyName)"
    }
}
