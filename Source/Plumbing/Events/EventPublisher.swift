import Foundation
import Combine

/*
 * An object to manage sending events
 * http://onmyway133.com/blog/How-to-reload-data-without-using-onAppear-in-SwiftUI-in-watchOS/
 */
class EventPublisher: ObservableObject {

    let loginRequiredTopic = PassthroughSubject<LoginRequiredEvent, Never>()
    let getDataTopic = PassthroughSubject<GetDataEvent, Never>()
    let reloadDataTopic = PassthroughSubject<ReloadEvent, Never>()

    /*
     * Publish an event to inform views of the data loading state
     */
    func sendGetDataEvent(loaded: Bool) {

        let event = GetDataEvent(loaded: loaded)
        getDataTopic.send(event)
    }

    /*
     * Publish an event to inform views that the user must authenticate
     */
    func sendLoginRequiredEvent() {

        let event = LoginRequiredEvent()
        loginRequiredTopic.send(event)
    }

    /*
     * Publish the reload event for the named view, which views can subscribe to via their onReceive handler
     */
    func sendReloadEvent(viewName: String, causeError: Bool) {

        let data = ReloadEvent(viewName: viewName, causeError: causeError)
        reloadDataTopic.send(data)
    }
}
