import Foundation

/*
 * Data and non UI logic for the user info view
 */
class UserInfoViewModel: ObservableObject {

    // Late initialised properties
    private let authenticator: Authenticator
    private let apiClient: ApiClient
    private let apiViewEvents: ApiViewEvents

    // Published state
    @Published var oauthUserInfo: OAuthUserInfo?
    @Published var apiUserInfo: ApiUserInfo?

    // A helper to package concurrent API requests
    struct ApiRequests {
        var getOAuthUserInfo: OAuthUserInfo
        var getApiUserInfo: ApiUserInfo
    }

    /*
     * Receive global objects whenever the view is recreated
     */
    init(authenticator: Authenticator, apiClient: ApiClient, apiViewEvents: ApiViewEvents) {
        self.authenticator = authenticator
        self.apiClient = apiClient
        self.apiViewEvents = apiViewEvents
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

        self.apiViewEvents.onViewLoading(name: ApiViewNames.UserInfo)
        Task {

            do {

                // The UI gets OAuth user info from the authorization server
                async let getOAuthUserInfo = try await self.authenticator.getUserInfo()

                // The UI gets domain specific user attributes from its API
                let requestOptions = ApiRequestOptions(causeError: options.causeError)
                async let getApiUserInfo = try await self.apiClient.getUserInfo(options: requestOptions)

                // Fire both requests in parallel and wait for both to complete
                let results = try await ApiRequests(getOAuthUserInfo: getOAuthUserInfo, getApiUserInfo: getApiUserInfo)

                await MainActor.run {

                    // Update published properties on the main thread
                    self.oauthUserInfo = results.getOAuthUserInfo
                    self.apiUserInfo = results.getApiUserInfo
                    self.apiViewEvents.onViewLoaded(name: ApiViewNames.UserInfo)
                }

            } catch {

                await MainActor.run {

                    // Handle errors
                    self.oauthUserInfo = nil
                    self.apiUserInfo = nil
                    let uiError = ErrorFactory.fromException(error: error)
                    onError(uiError)
                    self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.UserInfo, error: uiError)
                }
            }
        }
    }

    /*
     * Remove user info after logout
     */
    func clearData() {
        self.oauthUserInfo = nil
        self.apiUserInfo = nil
    }

    /*
     * Return the user name from OAuth user info
     */
    func getUserName() -> String {

        if self.oauthUserInfo == nil {
            return ""
        }

        return "\(self.oauthUserInfo!.givenName) \(self.oauthUserInfo!.familyName)"
    }

    /*
     * Determine whether we need to load data
     */
    private func isLoaded() -> Bool {
        return self.oauthUserInfo != nil && self.apiUserInfo != nil
    }
}
