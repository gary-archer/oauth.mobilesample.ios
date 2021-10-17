import Foundation
import SwiftCoroutine
import SwiftUI

/*
 * A primitive view model class to manage global objects and state
 */
class AppViewModel: ObservableObject {

    // Global objects supplied during construction
    let dataReloadHandler: DataReloadHandler

    // Global objects created after configuration has been read
    private var configuration: Configuration?
    private var apiClient: ApiClient?
    private var authenticator: AuthenticatorImpl?

    // State used by the app view
    @Published var isInitialised = false
    @Published var isDeviceSecured = false
    @Published var isMainViewLoaded = false
    @Published var error: UIError?

    // View models for the screens that use API data are created once only
    @Published var companiesViewModel = CompaniesViewModel()
    @Published var transactionsViewModel = TransactionsViewModel()
    @Published var userInfoViewModel = UserInfoViewModel()

    /*
     * Receive environment objects
     */
    init(dataReloadHandler: DataReloadHandler) {
        self.dataReloadHandler = dataReloadHandler
    }

    /*
     * Initialise or reinitialise global objects, including processing configuration
     */
    func initialise(apiViewEvents: ApiViewEvents) throws {

        // Reset state flags
        self.isInitialised = false
        self.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        self.isMainViewLoaded = false

        // Load the configuration from the embedded resource
        self.configuration = try ConfigurationLoader.load()

        // Create the global authenticator
        self.authenticator = AuthenticatorImpl(configuration: self.configuration!.oauth)

        // Create the API Client from configuration
        self.apiClient = try ApiClient(
            appConfiguration: self.configuration!.app,
            authenticator: self.authenticator!)

        // Initialise view models that manage API data
        self.companiesViewModel.initialise(apiViewEvents: apiViewEvents, apiClient: self.apiClient!)
        self.transactionsViewModel.initialise(apiViewEvents: apiViewEvents, apiClient: self.apiClient!)
        self.userInfoViewModel.initialise(apiViewEvents: apiViewEvents, apiClient: self.apiClient!)

        // Indicate successful startup
        self.isInitialised = true
    }

    /*
     * Inform the view whether we are logged in
     */
    func isLoggedIn() -> Bool {
        return self.authenticator != nil && self.authenticator!.isLoggedIn()
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
     * Process login / logout responses if required
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
     * Handle an issue deep linking to transactions for company 1 when transactions for company 2 are active
     * In this case the onAppear function is not called within the transactions view so we need to force an update
     * https://github.com/onmyway133/blog/issues/468
     */
    func onDeepLinkCompleted(isSameView: Bool) {

        if isSameView {
            self.dataReloadHandler.sendReloadEvent(viewName: ApiViewNames.Main, causeError: false)
        }
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
        self.isMainViewLoaded = false
    }

    /*
     * Update session button state while the main view loads
     */
    func onMainLoadStateChanged(loaded: Bool) {
        self.isMainViewLoaded = loaded
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
