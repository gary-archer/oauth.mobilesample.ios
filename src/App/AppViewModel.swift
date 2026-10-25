import Foundation
import SwiftUI

/*
 * A view model class to manage global objects and state
 */
class AppViewModel: ObservableObject {

    // Global objects
    private let configuration: Configuration
    private let oauthClient: OAuthClient
    private let apiClient: ApiClient
    let eventBus: EventBus
    let viewModelStore: ViewModelStore
    var deepLinkStartupUrl: URL?

    // State used by the app view
    @Published var isLoaded: Bool
    @Published var isDeviceSecured: Bool
    @Published var error: UIError?
    @Published var sessionId: String

    // Child view models
    private var companiesViewModel: CompaniesViewModel?
    private var transactionsViewModel: TransactionsViewModel?
    private var userInfoViewModel: UserInfoViewModel?

    /*
     * Receive globals created by the app class
     */
    init(eventBus: EventBus) {

        // Create objects used for coordination
        self.eventBus = eventBus

        // Load the configuration from the embedded resource
        // swiftlint:disable:next force_try
        self.configuration = try! ConfigurationLoader.load()

        // Create the global OAuth client
        self.oauthClient = OAuthClientImpl(configuration: self.configuration.oauth)

        // Create the API Client from configuration
        // swiftlint:disable:next force_try
        self.apiClient = try! ApiClient(
            configuration: self.configuration,
            oauthClient: self.oauthClient,
            eventBus: self.eventBus)

        // Create an object to store view models
        self.viewModelStore = ViewModelStore(apiClient: self.apiClient, eventBus: self.eventBus)

        // Update state
        self.isLoaded = false
        self.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        self.error = nil
        self.sessionId = ""
    }

    /*
     * Initialization at startup, to load OpenID Connect metadata and any stored tokens
     */
    func initialize(onComplete: @escaping () -> Void) {

        Task {

            do {

                // Initialize and load the existing session from tokens if possible
                try await self.oauthClient.getSession()
                await MainActor.run {
                    self.isLoaded = true
                    self.sessionId = self.oauthClient.getDelegationId()
                    onComplete()
                }

            } catch {

                // Handle errors
                await MainActor.run {
                    self.error = ErrorFactory.fromException(error: error)
                }
            }
        }
    }

    /*
     * Indicate to the view whether logged in
     */
    func isLoggedIn() -> Bool {
        self.oauthClient.isLoggedIn()
    }

    /*
     * Do the login redirect
     */
    func login(viewController: UIViewController, onComplete: @escaping (Bool) -> Void) {

        self.apiClient.clearLoginState()

        Task {

            do {

                // Do the login redirect on the main thread
                try await MainActor.run {
                    try self.oauthClient.startLoginRedirect(viewController: viewController)
                }

                // Handle the login response on a background thread
                let response = try await self.oauthClient.handleLoginResponse()

                // Swap the code for tokens on a background thread
                try await self.oauthClient.finishLogin(authResponse: response)

                // Indicate success
                await MainActor.run {
                    self.sessionId = self.oauthClient.getDelegationId()
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

        self.apiClient.clearLoginState()

        Task {

            do {
                // Do the logout redirect on the main thread
                try await MainActor.run {
                    try self.oauthClient.startLogoutRedirect(viewController: viewController)
                }

                // Handle the logout response on a background thread
                _ = try await self.oauthClient.handleLogoutResponse()

                // Indicate success
                await MainActor.run {
                    self.sessionId = self.oauthClient.getDelegationId()
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

        if self.oauthClient.isOAuthResponse(responseUrl: url) {
            self.oauthClient.resumeOperation(responseUrl: url)
            return true
        }

        return false
    }

    /*
     * Publish an event to update all active views
     */
    func triggerDataReload(causeError: Bool) {

        self.error = nil
        self.eventBus.sendReloadDataEvent(causeError: causeError)
    }

    /*
     * See if the last batch of API requests resulted in errors
     */
    func hasErrors() -> Bool {
        return self.error != nil || self.apiClient.hasErrors()
    }

    /*
     * Make the access token act expired
     */
    func expireAccessToken() {
        self.oauthClient.expireAccessToken()
    }

    /*
     * Make the refresh token act expired
     */
    func expireRefreshToken() {
        self.oauthClient.expireRefreshToken()
    }

    /*
     * Make this value available for the session view
     */
    func getSessionId() -> String {
        return self.sessionId
    }
}
