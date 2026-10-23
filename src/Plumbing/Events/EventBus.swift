import Foundation
import Combine

/*
 * An object to manage publishing and subscribing to events
 */
class EventBus: ObservableObject {

    let navigatedTopic = PassthroughSubject<NavigatedEvent, Never>()
    let loginRequiredTopic = PassthroughSubject<LoginRequiredEvent, Never>()
    let apiRequestTopic = PassthroughSubject<ApiRequestEvent, Never>()
    let reloadDataTopic = PassthroughSubject<ReloadDataEvent, Never>()

    /*
     * Publish an event to inform views when the main view has changed
     */
    func sendNavigatedEvent(isAuthenticatedView: Bool) {

        let event = NavigatedEvent(isAuthenticatedView: isAuthenticatedView)
        self.navigatedTopic.send(event)
    }

    /*
     * Publish an event to inform views that the user must authenticate
     */
    func sendLoginRequiredEvent() {

        let event = LoginRequiredEvent()
        self.loginRequiredTopic.send(event)
    }

    /*
     * Publish an event when the first API request fires and when all API requests complete
     */
    func sendApiRequestEvent(loaded: Bool) {

        let event = ApiRequestEvent(loaded: loaded)
        self.apiRequestTopic.send(event)
    }

    /*
     * Publish the data reload event
     */
    func sendReloadDataEvent(causeError: Bool) {

        let data = ReloadDataEvent(causeError: causeError)
        self.reloadDataTopic.send(data)
    }
}
