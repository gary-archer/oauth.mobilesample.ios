import Foundation
import Combine

/*
 * An object to manage sending reload events
 * http://onmyway133.com/blog/How-to-reload-data-without-using-onAppear-in-SwiftUI-in-watchOS/
 */
class DataReloadHandler: ObservableObject {

    // An object to publish
    let objectWillChange = PassthroughSubject<(), Never>()

    // This is set by pressing or long pressing the reload button
    @Published var causeError: Bool = false

    /*
     * Publish the reload event, which views can subscribe to via their onReceive handler
     */
    func sendReloadEvent() {
        objectWillChange.send()
    }
}
