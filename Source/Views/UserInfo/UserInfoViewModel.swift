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
    func callApi(options: UserInfoLoadOptions, onError: @escaping (UIError) -> Void) {

        // Check preconditions
        if self.isLoaded() && !options.reload {
            self.apiViewEvents.onViewLoaded(name: ApiViewNames.UserInfo)
            return
        }

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {

                // Initialise for this request
                var newUserInfo: UserInfo?
                let requestOptions = ApiRequestOptions(causeError: options.causeError)

                // Make the API call on a background thread
                self.apiViewEvents.onViewLoading(name: ApiViewNames.UserInfo)
                try DispatchQueue.global().await {
                    newUserInfo = try self.apiClient.getUserInfo(options: requestOptions).await()
                }

                // Update published properties on the main thread
                self.userInfo = newUserInfo
                self.apiViewEvents.onViewLoaded(name: ApiViewNames.UserInfo)

            } catch {

                // Handle errors
                self.userInfo = nil
                let uiError = ErrorFactory.fromException(error: error)
                onError(uiError)
                self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.UserInfo, error: uiError)
            }
        }
    }

    /*
     * Remove user info after logout
     */
    func clearData() {
        self.userInfo = nil
    }

    /*
     * Return the user name to display
     */
    func getUserName() -> String {

        if self.userInfo == nil {
            return ""
        }

        return "\(self.userInfo!.givenName) \(self.userInfo!.familyName)"
    }

    /*
     * Determine whether we need to load data
     */
    private func isLoaded() -> Bool {
        return self.userInfo != nil
    }
}
