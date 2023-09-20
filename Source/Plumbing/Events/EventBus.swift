import Foundation
import Combine

/*
 * An object to manage publishing and subscribing to events
 */
class EventBus: ObservableObject {

    let navigatedTopic = PassthroughSubject<NavigatedEvent, Never>()
    let loginRequiredTopic = PassthroughSubject<LoginRequiredEvent, Never>()
    let viewModelFetchTopic = PassthroughSubject<ViewModelFetchEvent, Never>()
    let reloadMainViewTopic = PassthroughSubject<ReloadMainViewEvent, Never>()
    let reloadUserInfoTopic = PassthroughSubject<ReloadUserInfoEvent, Never>()

    /*
     * Publish an event to inform views when the main view has changed
     */
    func sendNavigatedEvent(isMainView: Bool) {

        let event = NavigatedEvent(isMainView: isMainView)
        navigatedTopic.send(event)
    }

    /*
     * Publish an event to inform views that the user must authenticate
     */
    func sendLoginRequiredEvent() {

        let event = LoginRequiredEvent()
        loginRequiredTopic.send(event)
    }

    /*
     * Publish an event to inform views of a fetch event
     */
    func sendViewModelFetchEvent(loaded: Bool) {

        let event = ViewModelFetchEvent(loaded: loaded)
        viewModelFetchTopic.send(event)
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
