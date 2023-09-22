import Foundation

/*
 * A cache item represents an API response
 */
class FetchCacheItem {

    var isLoading: Bool
    private var data: Data?
    private var error: UIError?

    init() {
        self.isLoading = true
        self.data = nil
        self.error = nil
    }

    func getData() -> Data? {
        return self.data
    }

    func setData(value: Data?) {
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
