import Foundation

/*
 * A cache item represents a succesful API response
 */
class FetchCacheItem {

    private var data: Data?

    init() {
        self.data = nil
    }

    func setData(value: Data?) {
        self.data = value
    }
    
    func getData() -> Data? {
        return self.data
    }
}
