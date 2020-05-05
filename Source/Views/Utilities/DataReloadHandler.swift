import Foundation
import Combine

/*
 * An object to manage sending reload events
 * http://onmyway133.com/blog/How-to-reload-data-without-using-onAppear-in-SwiftUI-in-watchOS/
 */
final class DataReloadHandler: ObservableObject {

    let objectWillChange = PassthroughSubject<(), Never>()

    /*
     * Publish the reload event, which views can subscribe to via their onReceive handler
     */
    func sendReloadEvent() {
        objectWillChange.send()
    }
}
