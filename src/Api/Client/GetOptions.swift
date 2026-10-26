import SwiftUI

/*
 * Input when making a cacheable GET request
 */
struct GetOptions {
    var cacheKey: String
    var forceReload: Bool
    var causeError: Bool
}
