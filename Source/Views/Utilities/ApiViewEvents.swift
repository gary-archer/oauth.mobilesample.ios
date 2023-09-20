import SwiftUI

/*
* A helper class to coordinate multiple views loading data from the API
*/
class ApiViewEvents {

    private let eventBus: EventBus
    private var views: [ApiViewLoadState]
    private var loginRequired = false

    /*
     * Set the initial state
     */
    init (eventBus: EventBus) {

        self.eventBus = eventBus
        self.views = [ApiViewLoadState]()
        self.loginRequired = false
    }

    /*
     * Each view is added along with an initial unloaded state
     */
    func addView(name: String) {

        let viewState = ApiViewLoadState(name: name, loaded: false, failed: false)
        views.append(viewState)
    }

    /*
     * Handle loading notifications, which will disable the header buttons
     */
    func onViewLoading(name: String) {

        self.updateLoadState(name: name, loaded: false, failed: false)

        if name == ApiViewNames.Main {
            self.eventBus.sendViewModelFetchEvent(loaded: false)
        }
    }

    /*
     * Update state when loaded, which may trigger a login redirect once all views are loaded
     */
    func onViewLoaded(name: String) {

        self.updateLoadState(name: name, loaded: true, failed: false)

        if name == ApiViewNames.Main {
            self.eventBus.sendViewModelFetchEvent(loaded: true)
        }

        self.triggerLoginIfRequired()
    }

    /*
     * Update state when loaded, which may trigger a login redirect once all views are loaded
     */
    func onViewLoadFailed(name: String, error: UIError) {

        self.updateLoadState(name: name, loaded: true, failed: true)

        if error.errorCode == ErrorCodes.loginRequired {
            self.loginRequired = true
        }

        self.triggerLoginIfRequired()
    }

    /*
     * Indicate if any view failed to load
     */
    func hasLoadError() -> Bool {

        let failedCount = self.views.filter({item in item.failed == true}).count
        return failedCount > 0
    }

    /*
     * Reset state when the Reload Data button is clicked
     */
    func clearState() {

        views.forEach({ item in
            item.loaded = false
            item.failed = false
        })

        self.loginRequired = false
    }

    /*
     * Update whether a view has finished trying to load
     */
    private func updateLoadState(name: String, loaded: Bool, failed: Bool) {

        let found = self.views.first(where: {item in item.name == name})
        if found != nil {
            found!.loaded = loaded
            found!.failed = failed
        }
    }

    /*
     * If all views are loaded and one or more has reported login required, then trigger a redirect
     */
    private func triggerLoginIfRequired() {

        let allViewsLoaded = self.views.filter({item in item.loaded == true}).count == self.views.count
        if allViewsLoaded && self.loginRequired {
            self.eventBus.sendLoginRequiredEvent()
        }
    }
}
