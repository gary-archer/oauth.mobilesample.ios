import Foundation

/*
 * A primitive view model class to manage global objects and state
 */
class AppViewModel: ObservableObject {

    // Global objects created after construction and used by the main app view
    @Published var configuration: Configuration?
    @Published var apiClient: ApiClient?
    @Published var authenticator: AuthenticatorImpl?

    // State used by the view
    @Published var isInitialised = false
    @Published var isDeviceSecured = false
    @Published var isDataLoaded = false
    @Published var isTopMost = true
    @Published var error: UIError?

    /*
     * Initialise or reinitialise data
     */
    func initialise() throws {

        // Reset state flags
        self.isInitialised = false
        self.isDeviceSecured = DeviceSecurity.isDeviceSecured()
        self.isDataLoaded = false
        self.isTopMost = true

        // Load the configuration from the embedded resource
        self.configuration = try ConfigurationLoader.load()

        // Create the global authenticator
        self.authenticator = AuthenticatorImpl(configuration: self.configuration!.oauth)

        // Create the API Client from configuration
        self.apiClient = try ApiClient(
            appConfiguration: self.configuration!.app,
            authenticator: self.authenticator!)

        // Indicate successful startup
        self.isInitialised = true
    }
}
