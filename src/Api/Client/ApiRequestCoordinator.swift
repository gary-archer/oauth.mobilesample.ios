/*
 * Called on the main thread to coordinate API requests from multiple views, and handles session expiry when required
 */
class ApiRequestCoordinator {

    private let fetchCache: FetchCache
    private let eventBus: EventBus
    private var cacheKeys: [String]
    private var loadingCount: Int
    private var loadedCount: Int
    private var errors: [UIError]

    /*
     * Set the initial state
     */
    init(fetchCache: FetchCache, eventBus: EventBus) {

        self.fetchCache = fetchCache
        self.eventBus = eventBus
        self.cacheKeys = []
        self.loadingCount = 0
        self.loadedCount = 0
        self.errors = []
    }

    /*
     * Called when an API request starts
     * Fires ApiRequestEvent(false) on the first request of a batch to signal loading has begun
     */
    func onApiRequestStart(cacheKey: String) {

        if self.loadingCount == 0 {
            self.cacheKeys = []
            self.eventBus.sendApiRequestEvent(loaded: false)
        }

        self.cacheKeys.append(cacheKey)
        self.loadingCount += 1
    }

    /*
     * Called when an API request ends
     * Fires ApiRequestEvent(true) once all pending requests in the batch have finished
     */
    func onApiRequestEnd() {

        self.loadedCount += 1
        self.handleAllRequestsComplete()
    }

    /*
     * Return true if there were any errors on the last batch of API requests
     */
    func hasErrors() -> Bool {
        return !self.errors.isEmpty
    }

    /*
         * Reset all state when the user logs out
         */
    func resetState() {

        self.errors = []
        self.cacheKeys = []
        self.loadingCount = 0
        self.loadedCount = 0
    }

    /*
     * Handle OAuth related errors once all requests in the batch finish
     */
    private func handleAllRequestsComplete() {

        if self.loadedCount == self.loadingCount {

            // Reset counts
            self.loadingCount = 0
            self.loadedCount = 0

            // Get error details stored in the fetch cache
            self.errors = self.getAllErrors()

            // Notify subscribers when all API requests have completed successfully
            if self.errors.isEmpty {
                self.eventBus.sendApiRequestEvent(loaded: true)
            }

            // Login required errors occur when there are no tokens yet or when token refresh fails
            // Raise a single event so that navigation to login required is triggered only once
            let loginRequired = self.errors.first { error in
                error.errorCode == ErrorCodes.loginRequired
            }
            if loginRequired != nil {
                self.eventBus.sendLoginRequiredEvent()
            }
        }
    }

    /*
     * Collect errors for the current batch of requests
     */
    private func getAllErrors() -> [UIError] {

        var errors = [UIError]()

        self.cacheKeys.forEach { key in

            let found = self.fetchCache.getItem(key: key)
            let error = found?.getError()
            if error != nil {
                errors.append(error!)
            }
        }

        return errors
    }
}
