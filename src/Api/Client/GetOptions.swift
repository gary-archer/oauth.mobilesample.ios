import SwiftUI

/*
 * Input from views to influence core API GET behaviors, including an option for error rehearsal
 */
struct GetOptions {
    var forceReload: Bool
    var causeError: Bool
}
