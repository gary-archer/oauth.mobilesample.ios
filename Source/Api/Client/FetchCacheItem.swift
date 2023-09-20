/*
 * A cache item represents an API response
 */
class FetchCacheItem {

    var isLoading: Bool
    private var data: Any?
    private var error: UIError?

    init() {
        self.isLoading = true
        self.data = nil
        self.error = nil
    }

    func getData() -> Any? {
        return self.data
    }

    func setData(value: Any?) {
        self.data = value
        self.isLoading = false
    }

    func getError() -> UIError? {
        return self.error
    }

    func setError(value: UIError?) {
        self.error = value
        self.isLoading = false
    }
}
