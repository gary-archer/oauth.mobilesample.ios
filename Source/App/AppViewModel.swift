import Foundation
import SwiftCoroutine
import SwiftUI

/*
 * A primitive view model class to manage global objects and state
 */
class AppViewModel: ObservableObject {

    // Global objects created after construction
    private var configuration: Configuration?
    private var apiClient: ApiClient?
    var authenticator: AuthenticatorImpl?
    var viewManager: ViewManager?

    // State used by the app view
    @Published var isInitialised = false
    @Published var isDeviceSecured = false
    @Published var isDataLoaded = false
    @Published var error: UIError?

    // View models for the screens that use API data are created once only
    @Published var companiesViewModel = CompaniesViewModel()
    @Published var transactionsViewModel = TransactionsViewModel()
    @Published var userInfoViewModel = UserInfoViewModel()

    /*
     * Initialise or reinitialise global objects, including processing configuration
     */
    func initialise(onLoginRequired: @escaping () -> Void) throws {

        // Reset state flags
        self.isInitialised = false
        self.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        self.isDataLoaded = false

        // Load the configuration from the embedded resource
        self.configuration = try ConfigurationLoader.load()

        // Create the global authenticator
        self.authenticator = AuthenticatorImpl(configuration: self.configuration!.oauth)

        // Create the API Client from configuration
        self.apiClient = try ApiClient(
            appConfiguration: self.configuration!.app,
            authenticator: self.authenticator!)

        // Create the view manager, to manage synchronising OAuth operations across multiple views
        self.viewManager = ViewManager()
        self.viewManager!.initialise(
            onLoadStateChanged: self.onLoadStateChanged,
            onLoginRequired: onLoginRequired)
        self.viewManager!.setViewCount(count: 2)

        // Initialise view models for the main views
        self.companiesViewModel.initialise(viewManager: self.viewManager!, apiClient: self.apiClient!)
        self.transactionsViewModel.initialise(viewManager: self.viewManager!, apiClient: self.apiClient!)
        self.userInfoViewModel.initialise(viewManager: self.viewManager!, apiClient: self.apiClient!)

        // Indicate successful startup
        self.isInitialised = true
    }

    /*
     * Do the login redirect
     */
    func login(
        viewController: UIViewController,
        onSuccess: @escaping () -> Void,
        onError: @escaping (UIError) -> Void) {

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {
                // Do the login redirect on the UI thread
                let response = try self.authenticator!.startLogin(viewController: viewController)
                    .await()

                // Do the code exchange on a background thread
                try DispatchQueue.global().await {
                    try self.authenticator!.finishLogin(authResponse: response)
                        .await()
                }

                // Update the view
                onSuccess()

            } catch {

                let uiError = ErrorHandler.fromException(error: error)
                if uiError.errorCode != ErrorCodes.redirectCancelled {
                    self.error = uiError
                }

                onError(uiError)
            }
        }
    }

    /*
     * Process any deep link notifications, including login / logout responses
     */
    func handleOAuthDeepLink(url: URL) -> Bool {

        // If this is not a login or logout response, the view router handles the deep link
        if !self.authenticator!.isOAuthResponse(responseUrl: url) {
            return false
        }

        // Handle claimed HTTPS scheme login or logout responses
        self.authenticator!.resumeOperation(responseUrl: url)
        return true
    }

    /*
     * The logout entry point
     */
    func logout(
        viewController: UIViewController,
        onSuccess: @escaping () -> Void,
        onError: @escaping (UIError) -> Void) {

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {
                // Ask the authenticator to do the OAuth work
                try self.authenticator!.logout(viewController: viewController)
                    .await()

                // Do post logout processing
                onSuccess()

            } catch {

                // Do post logout processing
                let uiError = ErrorHandler.fromException(error: error)
                onError(uiError)
            }
        }
    }

    /*
     * Update state after logging out
     */
    func onLogout() {
        self.userInfoViewModel.clearUserInfo()
        self.isDataLoaded = false
    }

    /*
     * Update session button state while the main view loads
     */
    private func onLoadStateChanged(loaded: Bool) {
        self.isDataLoaded = loaded
    }

    /*
     * Make the access token act expired
     */
    func onExpireAccessToken() {
        self.authenticator!.expireAccessToken()
    }

    /*
     * Make the refresh token act expired
     */
    func onExpireRefreshToken() {
        self.authenticator!.expireRefreshToken()
    }
}
