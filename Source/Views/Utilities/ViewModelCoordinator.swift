class ViewModelCoordinator {

    private let eventBus: EventBus
    private let fetchCache: FetchCache
    private let authenticator: Authenticator
    private var mainCacheKey: String
    private var loadingCount: Int
    private var loadedCount: Int

    /*
     * Set the initial state
     */
    init(eventBus: EventBus, fetchCache: FetchCache, authenticator: Authenticator) {
        self.eventBus = eventBus
        self.fetchCache = fetchCache
        self.authenticator = authenticator
        self.mainCacheKey = ""
        self.loadingCount = 0
        self.loadedCount = 0
    }

    /*
     * This is called when the companies or transactions view model start sending API requests
     */
    func onMainViewModelLoading() {

        // Update stats
        self.loadingCount += 1

        // Send an event so that a subscriber can show a UI effect, such as disabling header buttons
        self.eventBus.sendViewModelFetchEvent(loaded: false)
    }

    /*
     * This is called when the companies or transactions view model finish sending API requests
     */
    func onMainViewModelLoaded(cacheKey: String) {

        // Record the cache key so that we can look up its result later
        self.mainCacheKey = cacheKey
        self.loadedCount += 1

        // On success, send an event so that a subscriber can show a UI effect such as enabling header buttons
        let found = self.fetchCache.getItem(key: cacheKey)
        if found?.getData() != nil {
            self.eventBus.sendViewModelFetchEvent(loaded: true)
        }

        // Perform error logic after all views have loaded
        self.handleErrorsAfterLoad()
    }

    /*
     * This is called when the userinfo view model starts sending API requests
     */
    func onUserInfoViewModelLoading() {
        self.loadingCount += 1
    }

    /*
     * This is called when the userinfo view model finishes sending API requests
     */
    func onUserInfoViewModelLoaded() {
        self.loadedCount += 1
        self.handleErrorsAfterLoad()
    }

    /*
     * Return true if there were any load errors
     */
    func hasErrors() -> Bool {
        return !self.getLoadErrors().isEmpty
    }

    /*
     * Reset state when the Reload Data button is clicked
     */
    func resetState() {
    }

    /*
     * Handle OAuth related errors
     */
    private func handleErrorsAfterLoad() {

        if self.loadedCount == self.loadingCount {

            let errors = self.getLoadErrors()

            let loginRequired = errors.first { error in
                error.errorCode == ErrorCodes.loginRequired
            }
            if loginRequired != nil {
                self.eventBus.sendLoginRequiredEvent()
                return
            }

            // In normal conditions the following errors are likely to be OAuth configuration errors
            let oauthConfigurationError = errors.first { error in
                error.errorCode == ErrorCodes.invalidToken ||
                error.errorCode == ErrorCodes.insufficientScope ||
                error.errorCode == ErrorCodes.claimsFailure
            }

            // The sample's user behavior is to present an error, after which clicking Home runs a new login redirect
            // This allows the frontend application to get new tokens, which may fix the problem in some cases
            if oauthConfigurationError != nil {
                self.authenticator.clearLoginState()
            }
         }
     }

     /*
      * Get the result of loading all views
      */
     private func getLoadErrors() -> [UIError] {

         var errors = [UIError]()

         var keys = [String]()
         if !self.mainCacheKey.isEmpty {
             keys.append(self.mainCacheKey)
         }
         keys.append(FetchCacheKeys.OAuthUserInfo)
         keys.append(FetchCacheKeys.ApiUserInfo)

         keys.forEach { key in

             let found = self.fetchCache.getItem(key: key)
             let error = found?.getError()
             if error != nil {
                 errors.append(error!)
             }
         }

         return errors
     }
}
