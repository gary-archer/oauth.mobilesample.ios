import Foundation

/*
 * Data and non UI logic for the user info view
 */
class UserInfoViewModel: ObservableObject {

    // Late initialised properties
    private let fetchClient: FetchClient
    private let apiViewEvents: ApiViewEvents

    // Published state
    @Published var oauthUserInfo: OAuthUserInfo?
    @Published var apiUserInfo: ApiUserInfo?
    @Published var error: UIError?

    // A helper to package concurrent API requests
    struct ApiRequests {
        var getOAuthUserInfo: OAuthUserInfo
        var getApiUserInfo: ApiUserInfo
    }

    /*
     * Receive global objects whenever the view is recreated
     */
    init(fetchClient: FetchClient, apiViewEvents: ApiViewEvents) {
        self.fetchClient = fetchClient
        self.apiViewEvents = apiViewEvents
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ViewLoadOptions? = nil) {

        let fetchOptions = FetchOptions(causeError: options?.causeError ?? false)
        let forceReload = options?.forceReload ?? false

        // Check preconditions
        if self.isLoaded() && !forceReload {
            self.apiViewEvents.onViewLoaded(name: ApiViewNames.UserInfo)
            return
        }

        self.apiViewEvents.onViewLoading(name: ApiViewNames.UserInfo)
        self.error = nil

        Task {

            do {

                // The UI gets OAuth user info from the authorization server
                async let getOAuthUserInfo = try await self.fetchClient.getOAuthUserInfo(options: fetchOptions)

                // The UI gets domain specific user attributes from its API
                async let getApiUserInfo = try await self.fetchClient.getApiUserInfo(options: fetchOptions)

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
                    self.error = ErrorFactory.fromException(error: error)
                    self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.UserInfo, error: self.error!)
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
