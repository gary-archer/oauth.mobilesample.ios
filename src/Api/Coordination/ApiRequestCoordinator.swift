/*
 * Called on the main thread to coordinate API requests from multiple views, and handles session expiry when required
 */
class ApiRequestCoordinator {

    private let eventBus: EventBus
    private let fetchCache: FetchCache
    private var cacheKeys: [String]
    private var loadingCount: Int
    private var loadedCount: Int

    /*
     * Set the initial state
     */
    init(eventBus: EventBus, fetchCache: FetchCache) {
        self.eventBus = eventBus
        self.fetchCache = fetchCache
        self.cacheKeys = []
        self.loadingCount = 0
        self.loadedCount = 0
    }

    /*
     * Called by a view model when it starts an API request
     * Accepts one or more cache keys to support view models that make concurrent requests
     * Fires ApiRequestEvent(false) on the first request of a batch to signal loading has begun
     */
    func onApiRequestStart(cacheKeys: String...) {

        if self.loadingCount == 0 {
            self.cacheKeys = []
        }

        self.cacheKeys.append(contentsOf: cacheKeys)
        self.loadingCount += 1

        if self.loadingCount == 1 {
            self.eventBus.sendApiRequestEvent(loaded: false)
        }
    }

    /*
     * Called by a view model when its API request completes
     * Fires ApiRequestEvent(true) once all pending requests in the batch have finished
     */
    func onApiRequestEnd() {

        self.loadedCount += 1
        self.handleAllRequestsComplete()
    }

    /*
     * Return true if there were any load errors
     */
    func hasErrors() -> Bool {
        return !self.getLoadErrors().isEmpty
    }

    /*
     * Reset state when the Reload Data button is clicked or on logout
     */
    func resetState() {
        self.cacheKeys = []
        self.loadingCount = 0
        self.loadedCount = 0
        self.fetchCache.clearAll()
    }

    /*
     * Handle OAuth related errors once all requests in the batch finish
     */
    private func handleAllRequestsComplete() {

        if self.loadedCount == self.loadingCount {

            // Reset counts
            self.loadingCount = 0
            self.loadedCount = 0

            // Notify subscribers when all API requests have completed successfully
            let errors = self.getLoadErrors()
            if errors.isEmpty {
                self.eventBus.sendApiRequestEvent(loaded: true)
            }

            // Login required errors occur when there are no tokens yet or when token refresh fails
            // Raise a single event so that navigation to login required is triggered only once
            let loginRequired = errors.first { error in
                error.errorCode == ErrorCodes.loginRequired
            }
            if loginRequired != nil {
                self.resetState()
                self.eventBus.sendLoginRequiredEvent()
            }
        }
    }

    /*
     * Collect errors from all cache keys registered in the current batch
     */
    private func getLoadErrors() -> [UIError] {

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
