import Foundation

/*
 * A helper class to load configuration
 */
struct ConfigurationLoader {

    /*
     * Load configuration from the embedded resource
     */
    static func load() throws -> Configuration {

        // Load the configuration file
        guard let filePath = Bundle.main.path(forResource: "mobile_config", ofType: "json") else {
            throw ErrorFactory.fromMessage(message: "Unable to load mobile configuration file")
        }

        // Create the decoder
        let jsonText = try String(contentsOfFile: filePath)
        let jsonData = jsonText.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try decoder.decode(Configuration.self, from: jsonData)
    }
}
