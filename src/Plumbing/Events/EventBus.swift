import Foundation
import Combine

/*
 * An object to manage publishing and subscribing to events
 */
class EventBus: ObservableObject {

    let navigatedTopic = PassthroughSubject<NavigatedEvent, Never>()
    let loginRequiredTopic = PassthroughSubject<LoginRequiredEvent, Never>()
    let apiRequestsTopic = PassthroughSubject<ApiRequestsEvent, Never>()
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
     * Publish an event when a batch of API requests starts or ends
     */
    func sendApiRequestsEvent(completed: Bool) {

        let event = ApiRequestsEvent(completed: completed)
        self.apiRequestsTopic.send(event)
    }

    /*
     * Publish the data reload event
     */
    func sendReloadDataEvent(causeError: Bool) {

        let data = ReloadDataEvent(causeError: causeError)
        self.reloadDataTopic.send(data)
    }
}
