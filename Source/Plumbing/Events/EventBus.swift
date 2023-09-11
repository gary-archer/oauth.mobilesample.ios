import Foundation
import Combine

/*
 * An object to manage publishing and subscribing to events
 */
class EventBus: ObservableObject {

    let navigatedTopic = PassthroughSubject<NavigatedEvent, Never>()
    let loginRequiredTopic = PassthroughSubject<LoginRequiredEvent, Never>()
    let dataStatusTopic = PassthroughSubject<DataStatusEvent, Never>()
    let reloadMainViewTopic = PassthroughSubject<ReloadMainViewEvent, Never>()
    let reloadUserInfoTopic = PassthroughSubject<ReloadUserInfoEvent, Never>()
    let setErrorEventTopic = PassthroughSubject<SetErrorEvent, Never>()

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
     * Publish an event to inform views of the data loading state
     */
    func sendDataStatusEvent(loaded: Bool) {

        let event = DataStatusEvent(loaded: loaded)
        dataStatusTopic.send(event)
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

    /*
     * Publish the set error event for the error summary view
     */
    func sendSetErrorEvent(containingViewName: String, error: UIError?) {

        let data = SetErrorEvent(containingViewName: containingViewName, error: error)
        setErrorEventTopic.send(data)
    }
}
