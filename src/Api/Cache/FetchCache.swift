import Foundation

/*
 * A cache to prevent redundant HTTP requests
 * This is used when the data for a view has already been retrieved
 * This includes during back navigation and view recreation by the Android system
 */
class FetchCache {

    // A map of cache keys (URLs) to API responses
    private let queue: DispatchQueue
    private var cache: [String: Data]

    /*
     * Initialise data
     */
    init() {
        self.queue = DispatchQueue(label: "ConcurrentDictionary")
        self.cache = [String: Data]()
    }

    /*
     * Set an item with data
     */
    func setItem(key: String, data: Data) {
        self.cache[key] = data
    }

    /*
     * Get an item if it exists
     */
    func getItem(key: String) -> Data? {

        self.queue.sync {
            return self.cache[key]
        }
    }

    /*
     * Remove an item when forcing a reload
     */
    func removeItem(key: String) {

        self.queue.sync {
            _ = self.cache.removeValue(forKey: key)
        }
    }

    /*
     * Clear the cache when logging out
     */
    func clearAll() {

        self.queue.sync {
            self.cache = [String: Data]()
        }
    }
}
