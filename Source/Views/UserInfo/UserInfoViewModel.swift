import Foundation
import SwiftCoroutine

/*
 * Data and non UI logic for the user info view
 */
class UserInfoViewModel: ObservableObject {

    // Late initialised properties
    private var viewManager: ViewManager?
    private var apiClient: ApiClient?

    // Published state
    @Published var userInfo: UserInfoClaims?
    @Published var error: UIError?

    /*
     * Set objects once they have been created
     */
    func initialise(viewManager: ViewManager, apiClient: ApiClient) {
        self.viewManager = viewManager
        self.apiClient = apiClient
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ApiRequestOptions, shouldLoad: Bool) {

        // Check preconditions
        if !shouldLoad {
            self.viewManager!.onViewLoaded()
            return
        }

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {

                // Initialise for this request
                self.error = nil
                var newUserInfo: UserInfoClaims?

                // Make the API call on a background thread
                self.viewManager!.onViewLoading()
                try DispatchQueue.global().await {
                    newUserInfo = try self.apiClient!.getUserInfo(options: options).await()
                }

                // Update published properties on the main thread
                self.userInfo = newUserInfo
                self.viewManager!.onViewLoaded()

            } catch {

                // Handle errors
                let uiError = ErrorHandler.fromException(error: error)
                self.userInfo = nil
                self.error = uiError
                self.viewManager!.onViewLoadFailed(error: uiError)
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