import Foundation
import Combine

/*
 * An object to manage publishing and subscribing to events
 */
class EventBus: ObservableObject {

    let navigatedTopic = PassthroughSubject<NavigatedEvent, Never>()
    let loginRequiredTopic = PassthroughSubject<LoginRequiredEvent, Never>()
    let viewModelFetchTopic = PassthroughSubject<ViewModelFetchEvent, Never>()
    let reloadDataTopic = PassthroughSubject<ReloadDataEvent, Never>()

    /*
     * Publish an event to inform views when the main view has changed
     */
    func sendNavigatedEvent(isMainView: Bool) {

        let event = NavigatedEvent(isMainView: isMainView)
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
     * Publish an event to inform views of a fetch event
     */
    func sendViewModelFetchEvent(loaded: Bool) {

        let event = ViewModelFetchEvent(loaded: loaded)
        self.viewModelFetchTopic.send(event)
    }

    /*
     * Publish the data reload event
     */
    func sendReloadDataEvent(causeError: Bool) {

        let data = ReloadDataEvent(causeError: causeError)
        self.reloadDataTopic.send(data)
    }
}
