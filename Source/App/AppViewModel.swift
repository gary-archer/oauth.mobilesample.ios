import Foundation
import SwiftUI

/*
 * A primitive view model class to manage global objects and state
 */
class AppViewModel: ObservableObject {

    // Global objects
    private let configuration: Configuration
    private let authenticator: Authenticator
    private let fetchClient: FetchClient
    private let fetchCache: FetchCache
    let viewModelCoordinator: ViewModelCoordinator

    // State used by the app view
    @Published var isDeviceSecured = false
    @Published var error: UIError?

    // Child view models
    private var companiesViewModel: CompaniesViewModel?
    private var transactionsViewModel: TransactionsViewModel?
    private var userInfoViewModel: UserInfoViewModel?

    /*
     * Receive globals created by the app class
     */
    init(eventBus: EventBus) {

        // Create objects used for coordination
        self.fetchCache = FetchCache()
        self.viewModelCoordinator = ViewModelCoordinator(eventBus: eventBus, fetchCache: self.fetchCache)

        // Load the configuration from the embedded resource
        // swiftlint:disable:next force_try
        self.configuration = try! ConfigurationLoader.load()

        // Create the global authenticator
        self.authenticator = AuthenticatorImpl(configuration: self.configuration.oauth)

        // Create the API Client from configuration
        // swiftlint:disable:next force_try
        self.fetchClient = try! FetchClient(
            configuration: self.configuration,
            fetchCache: self.fetchCache,
            authenticator: self.authenticator)

        // Update state
        self.isDeviceSecured = DeviceSecurity.isDeviceSecured()
    }

    /*
     * Create the companies view model on first use
     */
    func getCompaniesViewModel() -> CompaniesViewModel {

        if self.companiesViewModel == nil {

            self.companiesViewModel = CompaniesViewModel(
                fetchClient: self.fetchClient,
                viewModelCoordinator: self.viewModelCoordinator)
        }

        return self.companiesViewModel!
    }

    /*
     * Create the transactions view model on first use
     */
    func getTransactionsViewModel() -> TransactionsViewModel {

        if self.transactionsViewModel == nil {

            self.transactionsViewModel = TransactionsViewModel(
                fetchClient: self.fetchClient,
                viewModelCoordinator: self.viewModelCoordinator)
        }

        return self.transactionsViewModel!
    }

    /*
     * Create the user info view model on first use
     */
    func getUserInfoViewModel() -> UserInfoViewModel {

        if self.userInfoViewModel == nil {
            self.userInfoViewModel = UserInfoViewModel(
                fetchClient: self.fetchClient,
                viewModelCoordinator: self.viewModelCoordinator)
        }

        return self.userInfoViewModel!
    }

    /*
     * Make this value available for the session view
     */
    func getSessionId() -> String {
        return self.fetchClient.sessionId
    }

    /*
     * Do the login redirect
     */
    func login(viewController: UIViewController, onComplete: @escaping (Bool) -> Void) {

        Task {

            do {

                // Clear state
                self.fetchCache.clearAll()
                self.viewModelCoordinator.resetState()

                // Make sure metadata is loaded
                try await self.authenticator.getMetadata()

                // Do the login redirect on the main thread
                try await MainActor.run {
                    try self.authenticator.startLoginRedirect(viewController: viewController)
                }

                // Handle the login response on a background thread
                let response = try await self.authenticator.handleLoginResponse()

                // Swap the code for tokens on a background thread
                try await self.authenticator.finishLogin(authResponse: response)

                // Indicate success
                await MainActor.run {
                    onComplete(false)
                }

            } catch {

                // Handle errors
                await MainActor.run {

                    let uiError = ErrorFactory.fromException(error: error)
                    if uiError.errorCode != ErrorCodes.redirectCancelled {

                        // Indicate failure
                        self.error = uiError
                        onComplete(false)

                    } else {

                        // Indicate cancellation
                        onComplete(true)
                    }
                }
            }
        }
    }

    /*
     * Do the logout redirect
     */
    func logout(viewController: UIViewController, onComplete: @escaping () -> Void) {

        Task {

            do {

                // Clear state
                self.fetchCache.clearAll()
                self.viewModelCoordinator.resetState()

                // Make sure metadata is loaded
                try await self.authenticator.getMetadata()

                // Do the logout redirect on the main thread
                try await MainActor.run {
                    try self.authenticator.startLogoutRedirect(viewController: viewController)
                }

                // Handle the logout response on a background thread
                _ = try await self.authenticator.handleLogoutResponse()

                // Indicate success
                await MainActor.run {
                    onComplete()
                }

            } catch {

                // Handle errors
                await MainActor.run {

                    // Only report logout failures to debug output
                    let uiError = ErrorFactory.fromException(error: error)
                    if uiError.errorCode != ErrorCodes.redirectCancelled {
                        ErrorConsoleReporter.output(error: uiError)
                    }

                    // Indicate completion
                    onComplete()
                }
            }
        }
    }

    /*
     * Resume login / logout responses when the app receives a claimed HTTPS scheme notification
     */
    func resumeOAuthResponse(url: URL) -> Bool {

        if self.authenticator.isOAuthResponse(responseUrl: url) {
            self.authenticator.resumeOperation(responseUrl: url)
            return true
        }

        return false
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
