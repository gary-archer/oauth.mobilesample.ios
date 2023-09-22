import Foundation

/*
 * Plumbing related to making HTTP calls
 */
class FetchClient {

    private var configuration: Configuration
    private var authenticator: Authenticator
    let sessionId: String

    init(configuration: Configuration, authenticator: Authenticator) throws {
        self.configuration = configuration
        self.authenticator = authenticator
        self.sessionId = UUID().uuidString
    }

    /*
     * Make an API call to get companies
     */
    func getCompanies(options: FetchOptions?) async throws -> [Company] {

        guard let url = URL(string: "\(self.configuration.app.apiBaseUrl)/companies") else {
            throw ErrorFactory.fromMessage(message: "Invalid API URL in FetchClient")
        }

        // Make the API call
        let data = try await self.callApi(
            method: "GET",
            url: url,
            jsonData: nil,
            options: options)

        // Deserialize and return data
        return try self.deserialize(data: data!)
    }

    /*
     * Get the list of transactions for a company
     */
    func getCompanyTransactions(
        companyId: String,
        options: FetchOptions?) async throws -> CompanyTransactions {

        guard let url = URL(string: "\(self.configuration.app.apiBaseUrl)/companies/\(companyId)/transactions") else {
            throw ErrorFactory.fromMessage(message: "Invalid API URL in FetchClient")
        }

        // Make the API call
        let data = try await self.callApi(
            method: "GET",
            url: url,
            jsonData: nil,
            options: options)

        // Deserialize and return data
        return try self.deserialize(data: data!)
    }

    /*
     * Download user attributes from the authorization server
     */
    func getOAuthUserInfo(options: FetchOptions?) async throws -> OAuthUserInfo {

        guard let url = URL(string: self.configuration.oauth.userInfoEndpoint) else {
            throw ErrorFactory.fromMessage(message: "Invalid user info endpoint in FetchClient")
        }

        // Make the API call
        let data = try await self.callApi(
            method: "GET",
            url: url,
            jsonData: nil,
            options: options)

        // Return the response data on success
        var givenName  = ""
        var familyName = ""
        if let json = try? JSONSerialization.jsonObject(with: data!, options: []) {

            if let fields = json as? [String: Any] {
                givenName = fields["given_name"] as? String ?? ""
                familyName = fields["family_name"] as? String ?? ""
            }
        }

        return OAuthUserInfo(givenName: givenName, familyName: familyName)
    }

    /*
     * Download user attributes stored in the API's own data
     */
    func getApiUserInfo(options: FetchOptions?) async throws -> ApiUserInfo {

        guard let url = URL(string: "\(self.configuration.app.apiBaseUrl)/userinfo") else {
            throw ErrorFactory.fromMessage(message: "Invalid API URL in FetchClient")
        }

        // Make the API call
        let data = try await self.callApi(
            method: "GET",
            url: url,
            jsonData: nil,
            options: options)

        // Deserialize and return data
        return try self.deserialize(data: data!)
    }

    /*
     * Do the HTTP plumbing to make the remote call
     */
    private func callApi(
        method: String,
        url: URL,
        jsonData: Data?,
        options: FetchOptions?) async throws -> Data? {

        // Get the current access token
        var accessToken = try await authenticator.getAccessToken()

        do {
            // Call the API with the current token
            return try await self.callApiWithToken(
                method: method,
                url: url,
                jsonData: nil,
                accessToken: accessToken,
                options: options)

        } catch {

            // Handle 401s specially
            let uiError = ErrorFactory.fromException(error: error)
            if uiError.statusCode == 401 {

                // Try to refresh the access token
                accessToken = try await authenticator.refreshAccessToken()

                // Call the API again with the new token
                return try await self.callApiWithToken(
                    method: method,
                    url: url,
                    jsonData: nil,
                    accessToken: accessToken,
                    options: options)
            }

            throw error
        }
    }

    /*
     * Make an async request for data
     */
    private func callApiWithToken(
        method: String,
        url: URL,
        jsonData: Data?,
        accessToken: String,
        options: FetchOptions?) async throws -> Data? {

        // Create the request object and set parameters
        var request = URLRequest(url: url, timeoutInterval: 10.0)
        request.httpMethod = method

        // Add the access token to the request and then any custom headers
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Add other headers
        request.addValue("BasicIosApp", forHTTPHeaderField: "x-mycompany-api-client")
        request.addValue(self.sessionId, forHTTPHeaderField: "x-mycompany-session-id")
        request.addValue(UUID().uuidString, forHTTPHeaderField: "x-mycompany-correlation-id")

        // A special header can be sent to thr API to cause a simulated exception
        if options != nil && options!.causeError {
            request.addValue("SampleApi", forHTTPHeaderField: "x-mycompany-test-exception")
        }

        // Add body data if supplied
        if jsonData != nil {
            request.httpBody = jsonData
        }

        // Send the request and get the response
        do {

            let (data, response) = try await URLSession.shared.data(for: request)

            // Get the response as an HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {

                throw ErrorFactory.fromMessage(
                    message: "Invalid HTTP response object received after an API call")
            }

            // Check for a successful status
            if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {

                throw ErrorFactory.fromHttpResponseError(
                    response: httpResponse,
                    data: data,
                    url: url.absoluteString)
            }

            // Return the response data on success
            return data

        } catch {

            throw ErrorFactory.fromHttpRequestError(error: error, url: url.absoluteString)
        }
    }

    /*
     * A utility to deserialize data into an object
     */
    private func deserialize<T: Decodable>(data: Data) throws -> T {

        let decoder = JSONDecoder()
        if let result = try? decoder.decode(T.self, from: data) {
            return result
        } else {
            throw ErrorFactory.fromMessage(message: "Unable to deserialize data")
        }
    }
}
