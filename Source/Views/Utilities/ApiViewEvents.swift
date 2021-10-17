import SwiftUI

/*
* A helper class to coordinate multiple views loading data from the API
*/
class ApiViewEvents {

    // Properties
    private var views: [String: Bool]
    private var loginRequired: Bool

    // Callbacks to the AppView
    private var onLoginRequiredAction: (() -> Void)?
    private var onMainLoadStateChanged: ((Bool) -> Void)?

    /*
     * Set the initial state
     */
    init () {
        self.views = [String: Bool]()
        self.loginRequired = false
    }

    /*
     * Do late initialisation when the app view loads
     */
    func initialise(
        onLoginRequiredAction: @escaping () -> Void,
        onMainLoadStateChanged: @escaping (Bool) -> Void) {

        self.onLoginRequiredAction = onLoginRequiredAction
        self.onMainLoadStateChanged = onMainLoadStateChanged
    }

    /*
     * Each view is added along with an initial unloaded state
     */
    func addView(name: String) {
        views[name] = false
    }

    /*
     * Handle loading notifications, which will disable the header buttons
     */
    func onViewLoading(name: String) {

        views[name] = false

        if name == ApiViewNames.Main {
            self.onMainLoadStateChanged!(false)
        }
    }

    /*
     * Update state when loaded, which may trigger a login redirect once all views are loaded
     */
    func onViewLoaded(name: String) {

        views[name] = true

        if name == ApiViewNames.Main {
            self.onMainLoadStateChanged!(true)
        }

        self.triggerLoginIfRequired()
    }

    /*
     * Update state when loaded, which may trigger a login redirect once all views are loaded
     */
    func onViewLoadFailed(name: String, error: UIError) {

        views[name] = true

        if error.errorCode == ErrorCodes.loginRequired {
            self.loginRequired = true
        }

        self.triggerLoginIfRequired()
    }

    /*
     * Reset state when the Reload Data button is clicked
     */
    func clearState() {

        self.loginRequired = false

        views.forEach({ item in
            views[item.key] = false
        })
    }

    /*
     * If all views are loaded and one or more has reported login required, then trigger a redirect
     */
    private func triggerLoginIfRequired() {

        let allViewsLoaded = self.views.filter({item in item.value == true}).count == self.views.count
        if allViewsLoaded && self.loginRequired {
            self.onLoginRequiredAction!()
        }
    }
}
