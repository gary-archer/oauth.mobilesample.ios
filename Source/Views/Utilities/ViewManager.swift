import SwiftUI

/*
* A helper class to coordinate multiple views
*/
class ViewManager {

    // Flags used to update header button state
    private var mainViewLoaded: Bool
    private var userInfoLoaded: Bool

    // View errors when calling the API
    private var mainViewLoadError: UIError?
    private var userInfoLoadError: UIError?

    // Callbacks to the AppView
    private var onLoadStateChanged: (Bool) -> Void
    private var onLoginRequired: () -> Void

    /*
     * Initialise from input
     */
    init (
        onLoadStateChanged: @escaping (Bool) -> Void,
        onLoginRequired: @escaping () -> Void) {

        self.mainViewLoaded = false
        self.userInfoLoaded = false
        self.mainViewLoadError = nil
        self.userInfoLoadError = nil

        self.onLoadStateChanged = onLoadStateChanged
        self.onLoginRequired = onLoginRequired
    }

    /*
     * Handle the main view loading event
     */
    func onMainViewLoading() {
        self.onLoadStateChanged(false)
    }

    /*
     * Handle the main view loaded event
     */
    func onMainViewLoaded() {
        self.mainViewLoaded = true
        self.mainViewLoadError = nil
        self.onLoadStateChanged(true)
    }

    /*
     * Handle the main view load failed event
     */
    func onMainViewLoadFailed(error: UIError) {
        self.mainViewLoaded = true
        self.mainViewLoadError = error
        self.triggerLoginIfRequired()
    }

    /*
     * After a successful user info load, reset error state
     */
    func onUserInfoLoaded() {
        self.userInfoLoaded = true
        self.userInfoLoadError = nil
    }

    /*
     * After a failed user info load, store the error
     */
    func onUserInfoLoadFailed(error: UIError) {
        self.userInfoLoaded = true
        self.userInfoLoadError = error
        self.triggerLoginIfRequired()
    }

    /*
     * Indicate if there is an error
     */
    func hasError() -> Bool {

        let mainError = self.mainViewLoadError
        let userError = self.userInfoLoadError

        if (mainError != nil && mainError!.errorCode != ErrorCodes.loginRequired) ||
           (userError != nil && userError!.errorCode != ErrorCodes.loginRequired) {
            return true
        }

        return false
    }

    /*
    * Wait for both the main view and user info to load, then trigger a login redirect
    */
    private func triggerLoginIfRequired() {

        let mainError = self.mainViewLoadError
        let userError = self.userInfoLoadError

        // First check both views are loaded
        if self.mainViewLoaded && self.userInfoLoaded {

            // Next check if there is one or more login required errors
            if (mainError != nil && mainError!.errorCode == ErrorCodes.loginRequired) ||
               (userError != nil && userError!.errorCode == ErrorCodes.loginRequired) {

                // Ask the parent to trigger a login redirect
                self.onLoginRequired()
            }
        }
    }
}
