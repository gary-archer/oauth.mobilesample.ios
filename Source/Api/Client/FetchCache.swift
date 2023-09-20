import Foundation

/*
 * A cache to prevent redundant HTTP requests
 * This is used when the data for a view has already been retrieved
 * This includes during back navigation and view recreation by the Android system
 */
class FetchCache {

    // A map of cache keys to API responses
    private let queue: DispatchQueue
    private var cache: [String: FetchCacheItem]

    /*
     * Initialise data
     */
    init() {
        self.queue = DispatchQueue(label: "ConcurrentDictionary")
        self.cache = [String: FetchCacheItem]()
    }

    /*
     * Create an item with no data when an API request is triggered
     */
    func createItem(key: String) -> FetchCacheItem {

        var item = self.getItem(key: key)
        if item == nil {

            item = FetchCacheItem()
            self.queue.sync {
                self.cache[key] = item
            }
        }

        return item!
    }

    /*
     * Get an item if it exists
     */
    func getItem(key: String) -> FetchCacheItem? {
        return self.cache[key]
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
            self.cache = [String: FetchCacheItem]()
        }
    }
}
