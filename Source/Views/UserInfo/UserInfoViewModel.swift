import Foundation
import SwiftCoroutine

/*
 * Data and non UI logic for the user info view
 */
class UserInfoViewModel: ObservableObject {

    // Late initialised properties
    private let apiViewEvents: ApiViewEvents
    private let apiClient: ApiClient

    // Published state
    @Published var userInfo: UserInfo?
    @Published var error: UIError?

    /*
     * Receive global objects whenever the view is recreated
     */
    init(apiClient: ApiClient, apiViewEvents: ApiViewEvents) {
        self.apiViewEvents = apiViewEvents
        self.apiClient = apiClient
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ApiRequestOptions, shouldLoad: Bool) {

        // Check preconditions
        if !shouldLoad {
            self.apiViewEvents.onViewLoaded(name: ApiViewNames.UserInfo)
            return
        }

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {

                // Initialise for this request
                self.error = nil
                var newUserInfo: UserInfo?

                // Make the API call on a background thread
                self.apiViewEvents.onViewLoading(name: ApiViewNames.UserInfo)
                try DispatchQueue.global().await {
                    newUserInfo = try self.apiClient.getUserInfo(options: options).await()
                }

                // Update published properties on the main thread
                self.userInfo = newUserInfo
                self.apiViewEvents.onViewLoaded(name: ApiViewNames.UserInfo)

            } catch {

                // Handle errors
                let uiError = ErrorHandler.fromException(error: error)
                self.userInfo = nil
                self.error = uiError
                self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.UserInfo, error: uiError)
            }
        }
    }

    /*
     * Remove user info after logout
     */
    func clearUserInfo() {
        self.userInfo = nil
    }

    /*
     * Return the user name to display
     */
    func getUserName(shouldLoad: Bool) -> String {

        if !shouldLoad || self.userInfo == nil {
            return ""
        }

        return "\(self.userInfo!.givenName) \(self.userInfo!.familyName)"
    }
}
