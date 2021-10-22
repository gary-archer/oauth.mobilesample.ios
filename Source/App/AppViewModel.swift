import Foundation
import SwiftCoroutine
import SwiftUI

/*
 * A primitive view model class to manage global objects and state
 */
class AppViewModel: ObservableObject {

    // Global objects supplied during construction
    private let configuration: Configuration
    private let authenticator: Authenticator
    private let apiClient: ApiClient

    // Global objects used for view management
    let apiViewEvents: ApiViewEvents
    let eventBus: EventBus

    // State used by the app view
    @Published var isDeviceSecured = false
    @Published var hasData = false
    @Published var error: UIError?

    // Child view models
    private var companiesViewModel: CompaniesViewModel?
    private var transactionsViewModel: TransactionsViewModel?
    private var userInfoViewModel: UserInfoViewModel?

    /*
     * Receive environment objects
     */
    init(
        configuration: Configuration,
        authenticator: Authenticator,
        apiClient: ApiClient,
        eventBus: EventBus) {

        // Store input
        self.configuration = configuration
        self.authenticator = authenticator
        self.apiClient = apiClient
        self.eventBus = eventBus

        // Create a helper class to notify us about views that make API calls
        // This will enable us to only trigger a login redirect once, after all views have tried to load
        self.apiViewEvents = ApiViewEvents(eventBus: eventBus)
        self.apiViewEvents.addView(name: ApiViewNames.Main)
        self.apiViewEvents.addView(name: ApiViewNames.UserInfo)

        // Update state
        self.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        self.hasData = false
    }

    /*
     * Create the companies view model on first use
     */
    func getCompaniesViewModel() -> CompaniesViewModel {

        if self.companiesViewModel == nil {
            self.companiesViewModel = CompaniesViewModel(apiClient: self.apiClient, apiViewEvents: apiViewEvents)
        }

        return self.companiesViewModel!
    }

    /*
     * Create the transactions view model on first use
     */
    func getTransactionsViewModel() -> TransactionsViewModel {

        if self.transactionsViewModel == nil {
            self.transactionsViewModel = TransactionsViewModel(apiClient: self.apiClient, apiViewEvents: apiViewEvents)
        }

        return self.transactionsViewModel!
    }

    /*
     * Create the user info view model on first use
     */
    func getUserInfoViewModel() -> UserInfoViewModel {

        if self.userInfoViewModel == nil {
            self.userInfoViewModel = UserInfoViewModel(apiClient: self.apiClient, apiViewEvents: apiViewEvents)
        }

        return self.userInfoViewModel!
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
                let response = try self.authenticator.startLogin(viewController: viewController)
                    .await()

                // Do the code exchange on a background thread
                try DispatchQueue.global().await {
                    try self.authenticator.finishLogin(authResponse: response)
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
        if !self.authenticator.isOAuthResponse(responseUrl: url) {
            return false
        }

        // Handle claimed HTTPS scheme login or logout responses
        self.authenticator.resumeOperation(responseUrl: url)
        return true
    }

    /*
     * Handle an issue deep linking to transactions for company 1 when transactions for company 2 are active
     * In this case the onAppear function is not called within the transactions view so we need to force an update
     * https://github.com/onmyway133/blog/issues/468
     */
    func onDeepLinkCompleted(isSameView: Bool) {

        if isSameView {
            self.eventBus.sendReloadMainViewEvent(causeError: false)
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
                try self.authenticator.logout(viewController: viewController)
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
        self.userInfoViewModel!.clearUserInfo()
        self.hasData = false
    }

    /*
     * Make the access token act expired
     */
    func onExpireAccessToken() {
        self.authenticator.expireAccessToken()
    }

    /*
     * Make the refresh token act expired
     */
    func onExpireRefreshToken() {
        self.authenticator.expireRefreshToken()
    }
}
