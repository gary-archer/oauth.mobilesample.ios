import Foundation
import Combine

/*
 * An object to manage sending reload events
 * http://onmyway133.com/blog/How-to-reload-data-without-using-onAppear-in-SwiftUI-in-watchOS/
 */
class DataReloadHandler: ObservableObject {

    // An object to publish
    let objectWillChange = PassthroughSubject<Bool, Never>()

    /*
     * Publish the reload event, which views can subscribe to via their onReceive handler
     */
    func sendReloadEvent(causeError: Bool) {
        objectWillChange.send(causeError)
    }
}
