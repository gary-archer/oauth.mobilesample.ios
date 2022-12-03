import Foundation
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

    // State used by the app view
    @Published var isDeviceSecured = false

    // Child view models
    private var companiesViewModel: CompaniesViewModel?
    private var transactionsViewModel: TransactionsViewModel?
    private var userInfoViewModel: UserInfoViewModel?

    /*
     * Receive globals created by the app class
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

        // Create a helper class to notify us about views that make API calls
        // This will enable us to only trigger a login redirect once, after all views have tried to load
        self.apiViewEvents = ApiViewEvents(eventBus: eventBus)
        self.apiViewEvents.addView(name: ApiViewNames.Main)
        self.apiViewEvents.addView(name: ApiViewNames.UserInfo)

        // Update state
        self.isDeviceSecured = DeviceSecurity.isDeviceSecured()
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
     * Make this value available for the session view
     */
    func getSessionId() -> String {
        return self.apiClient.sessionId
    }

    /*
     * Do the login redirect
     */
    func login(
        viewController: UIViewController,
        onSuccess: @escaping () -> Void,
        onError: @escaping (UIError) -> Void) {

        Task {

            do {
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

                // Update the view
                onSuccess()

            } catch {

                // Report any caught errors
                onError(ErrorFactory.fromException(error: error))
            }
        }
    }

    /*
     * The logout entry point
     */
    func logout(
        viewController: UIViewController,
        onSuccess: @escaping () -> Void,
        onError: @escaping (UIError) -> Void) {

        Task {

            do {
                // Make sure metadata is loaded
                try await self.authenticator.getMetadata()

                // Do the logout redirect on the main thread
                try await MainActor.run {
                    try self.authenticator.startLogoutRedirect(viewController: viewController)
                }

                // Handle the logout response on a background thread
                _ = try await self.authenticator.handleLogoutResponse()

                // Update the view
                onSuccess()

            } catch {

                // Report any caught errors
                onError(ErrorFactory.fromException(error: error))
            }
        }
    }

    /*
     * Resume login / logout responses when the app receives a claimed HTTPS scheme notification
     */
    func resumeOAuthResponse(url: URL) {
        self.authenticator.resumeOperation(responseUrl: url)
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
