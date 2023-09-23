import SwiftUI

/*
 * Input when making a cacheable fetch request
 */
struct FetchOptions {
    var cacheKey: String
    var forceReload: Bool
    var causeError: Bool
}
