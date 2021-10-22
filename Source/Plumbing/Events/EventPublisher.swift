import Foundation
import Combine

/*
 * An object to manage sending events
 * http://onmyway133.com/blog/How-to-reload-data-without-using-onAppear-in-SwiftUI-in-watchOS/
 */
class EventPublisher: ObservableObject {

    let loginRequiredTopic = PassthroughSubject<LoginRequiredEvent, Never>()
    let dataStatusTopic = PassthroughSubject<DataStatusEvent, Never>()
    let reloadMainViewTopic = PassthroughSubject<ReloadMainViewEvent, Never>()
    let reloadUserInfoTopic = PassthroughSubject<ReloadUserInfoEvent, Never>()

    /*
     * Publish an event to inform views of the data loading state
     */
    func sendDataStatusEvent(loaded: Bool) {

        let event = DataStatusEvent(loaded: loaded)
        dataStatusTopic.send(event)
    }

    /*
     * Publish an event to inform views that the user must authenticate
     */
    func sendLoginRequiredEvent() {

        let event = LoginRequiredEvent()
        loginRequiredTopic.send(event)
    }

    /*
     * Publish the reload event for the main view
     */
    func sendReloadMainViewEvent(causeError: Bool) {

        let data = ReloadMainViewEvent(causeError: causeError)
        reloadMainViewTopic.send(data)
    }

    /*
     * Publish the reload event for the user info view
     */
    func sendReloadUserInfoEvent(causeError: Bool) {

        let data = ReloadUserInfoEvent(causeError: causeError)
        reloadUserInfoTopic.send(data)
    }
}
