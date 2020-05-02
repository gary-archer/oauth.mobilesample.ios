import Foundation

/*
 * Global data / view model used by our app that can be mutated
 */
class AppData: ObservableObject {

    // Properties used by the app view and passed to child views
    @Published var isInitialised = false
    @Published var configuration: Configuration?
    @Published var apiClient: ApiClient?
    @Published var authenticator: AuthenticatorImpl?
    @Published var viewManager: ViewManager?

    /*
     * Initialise data after the model has been created
     */
    func initialise(
        onLoadStateChanged: @escaping (Bool) -> Void,
        onLoginRequired: @escaping () -> Void) throws {

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

        // Create the view manager and set the initial count to the main view and user info
        self.viewManager = ViewManager(
            onLoadStateChanged: onLoadStateChanged,
            onLoginRequired: onLoginRequired)
        self.viewManager!.setViewCount(count: 2)

        // Indicate successful startup
        self.isInitialised = true
    }
}
