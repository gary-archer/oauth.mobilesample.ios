import SwiftUI

/*
* A helper class to coordinate multiple views loading data from the API
*/
class ViewManager {

    // Properties
    private var viewsToLoad: Int
    private var loadedCount: Int
    var hasErrors: Bool
    private var loginRequired: Bool

    // Callbacks to the AppView
    private var onLoadStateChanged: (Bool) -> Void
    private var onLoginRequired: () -> Void

    /*
     * Initialise from input
     */
    init (
        onLoadStateChanged: @escaping (Bool) -> Void,
        onLoginRequired: @escaping () -> Void) {

        self.onLoadStateChanged = onLoadStateChanged
        self.onLoginRequired = onLoginRequired

        // Default to loading a single view, unless the parent informs us otherwise
        self.viewsToLoad = 1
        self.loadedCount = 0
        self.hasErrors = false
        self.loginRequired = false
    }

    /*
     * Record the number of views to load
     */
    func setViewCount(count: Int) {
        self.viewsToLoad = count
    }

    /*
     * Handle the view loading event and inform the parent, which can render a loading state
     */
    func onViewLoading() {
        self.onLoadStateChanged(false)
    }

    /*
     * Handle the view loaded event and call back the parent when all loading is complete
     */
    func onViewLoaded() {

        self.loadedCount +=  1

        // Once all views have loaded, inform the parent if all views loaded successfully
        if self.loadedCount == self.viewsToLoad && !self.hasErrors {

            self.reset()
            self.onLoadStateChanged(true)
        }
    }

    /*
     * Handle the view load failed event
     */
    func onViewLoadFailed(error: UIError) {

        self.loadedCount +=  1
        self.hasErrors = true

        // Record if this was a login required error
        if error.errorCode == ErrorCodes.loginRequired {
            self.loginRequired = true
        }

        // Once all views have loaded, reset state and, if required, trigger a login redirect only once
        if self.loadedCount == self.viewsToLoad {

            let triggerLoginOnParent = self.loginRequired
            self.reset()

            if triggerLoginOnParent {
                self.onLoginRequired()
            }
        }
    }

    /*
     * Once loading is complete, ensure that there is no leftover state
     */
    private func reset() {
        self.viewsToLoad = 1
        self.loadedCount = 0
        self.hasErrors = false
        self.loginRequired = false
    }
}
