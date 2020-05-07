import Foundation

/*
 * Global data / view model used by our app that can be mutated
 * We cannot mutate normal properties within the view itself, which is a struct
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
    @Published var error: UIError?

    /*
     * Initialise or reinitialise data
     */
    func initialise() throws {

        // Reset state flags
        self.isInitialised = false
        self.isDeviceSecured = DeviceSecurity().isDeviceSecured()
        self.isDataLoaded = false

        // Load the configuration file
        guard let filePath = Bundle.main.path(forResource: "mobile_config", ofType: "json") else {
            throw ErrorHandler().fromMessage(message: "Unable to load mobile configuration file")
        }

        // Create the decoder
        let jsonText = try String(contentsOfFile: filePath)
        let jsonData = jsonText.data(using: .utf8)!
        let decoder = JSONDecoder()

        // Deserialize into an object
        if let configuration = try? decoder.decode(Configuration.self, from: jsonData) {
            self.configuration = configuration
        } else {
            throw ErrorHandler().fromMessage(message: "Unable to deserialize mobile configuration file JSON data")
        }

        // Create the global authenticator
        self.authenticator = AuthenticatorImpl(configuration: configuration!.oauth)

        // Create the API Client from configuration
        self.apiClient = try ApiClient(
            appConfiguration: self.configuration!.app,
            authenticator: self.authenticator!)

        // Indicate successful startup
        self.isInitialised = true
    }
}
