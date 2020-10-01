import SwiftUI

/*
 * Special options when making an API request
 */
struct ApiRequestOptions {

    // We can send an option to make the API fail, to demonstrate 500 handling
    var causeError: Bool
}
