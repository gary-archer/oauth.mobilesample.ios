import Foundation

/*
 * Data and non UI logic for the user info view
 */
class UserInfoViewModel: ObservableObject {

    // Late initialised properties
    private let fetchClient: FetchClient
    private let viewModelCoordinator: ViewModelCoordinator

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
    init(fetchClient: FetchClient, viewModelCoordinator: ViewModelCoordinator) {
        self.fetchClient = fetchClient
        self.viewModelCoordinator = viewModelCoordinator
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ViewLoadOptions? = nil) {

        let oauthFetchOptions = FetchOptions(
            cacheKey: FetchCacheKeys.OAuthUserInfo,
            forceReload: options?.forceReload ?? false,
            causeError: options?.causeError ?? false)

        let apiFetchOptions = FetchOptions(
            cacheKey: FetchCacheKeys.ApiUserInfo,
            forceReload: options?.forceReload ?? false,
            causeError: options?.causeError ?? false)

        // Initialise state
        self.viewModelCoordinator.onUserInfoViewModelLoading()
        self.error = nil

        Task {

            do {

                // The UI gets OAuth user info from the authorization server
                async let getOAuthUserInfo = try await self.fetchClient.getOAuthUserInfo(options: oauthFetchOptions)

                // The UI gets domain specific user attributes from its API
                async let getApiUserInfo = try await self.fetchClient.getApiUserInfo(options: apiFetchOptions)

                // Fire both requests in parallel and wait for both to complete
                let results = try await ApiRequests(getOAuthUserInfo: getOAuthUserInfo, getApiUserInfo: getApiUserInfo)

                await MainActor.run {

                    // Update state and notify
                    if results.getOAuthUserInfo != nil {
                        self.oauthUserInfo = results.getOAuthUserInfo
                    }
                    if results.getApiUserInfo != nil {
                        self.apiUserInfo = results.getApiUserInfo
                    }
                    self.viewModelCoordinator.onUserInfoViewModelLoaded()
                }

            } catch {

                await MainActor.run {

                    // Update state and notify
                    self.oauthUserInfo = nil
                    self.apiUserInfo = nil
                    self.error = ErrorFactory.fromException(error: error)
                    self.viewModelCoordinator.onUserInfoViewModelLoaded()
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
