import Foundation

/*
 * Plumbing related to making HTTP calls
 */
class ApiClient {

    private var apiBaseUrl: URL
    private var authenticator: Authenticator
    let sessionId: String

    init(appConfiguration: AppConfiguration, authenticator: Authenticator) throws {

        guard let url = URL(string: appConfiguration.apiBaseUrl) else {
            throw ErrorFactory.fromMessage(message: "Invalid base URL received in API Client")
        }

        self.apiBaseUrl = url
        self.authenticator = authenticator
        self.sessionId = UUID().uuidString
    }

    /*
     * Make an API call to get user info
     */
    func getUserInfo(options: ApiRequestOptions?) async throws -> UserInfo {

        // Make the API call
        let data = try await self.callApi(
            path: "userinfo",
            method: "GET",
            jsonData: nil,
            options: options)

        // Deserialize and return data
        let userInfo: UserInfo = try self.deserialize(data: data!)
        return userInfo
    }

    /*
     * Make an API call to get companies
     */
    func getCompanies(options: ApiRequestOptions?) async throws -> [Company] {

        // Make the API call
        let data = try await self.callApi(
            path: "companies",
            method: "GET",
            jsonData: nil,
            options: options)

        // Deserialize and return data
        let companies: [Company] = try self.deserialize(data: data!)
        return companies
    }

    /*
     * Get the list of transactions for a company
     */
    func getCompanyTransactions(
        companyId: String,
        options: ApiRequestOptions?) async throws -> CompanyTransactions {

        // Make the API call
        let data = try await self.callApi(
            path: "companies/\(companyId)/transactions",
            method: "GET",
            jsonData: nil,
            options: options)

        // Deserialize and return data
        let transactions: CompanyTransactions = try self.deserialize(data: data!)
        return transactions
    }

    /*
     * Do the HTTP plumbing to make the remote call
     */
    private func callApi(
        path: String,
        method: String,
        jsonData: Data?,
        options: ApiRequestOptions?) async throws -> Data? {

        // Get the full URL
        let requestUrl = apiBaseUrl.appendingPathComponent(path)

        // Get the current access token
        var accessToken = try await authenticator.getAccessToken()

        do {
            // Call the API with the current token
            return try await self.callApiWithToken(
                requestUrl: requestUrl,
                method: method,
                jsonData: nil,
                accessToken: accessToken,
                options: options)

        } catch {

            // Handle 401s specially
            let uiError = ErrorFactory.fromException(error: error)
            if uiError.statusCode == 401 {

                // Try to refresh the access token
                accessToken = try await authenticator.refreshAccessToken()

                do {

                    // Call the API again with the new token
                    return try await self.callApiWithToken(
                        requestUrl: requestUrl,
                        method: method,
                        jsonData: nil,
                        accessToken: accessToken,
                        options: options)

                } catch {

                    // Report errors on the retry
                    throw error
                }
            }

            throw error
        }
    }

    /*
     * Make an async request for data
     */
    private func callApiWithToken(
        requestUrl: URL,
        method: String,
        jsonData: Data?,
        accessToken: String,
        options: ApiRequestOptions?) async throws -> Data? {

        // Create the request object and set parameters
        var request = URLRequest(url: requestUrl, timeoutInterval: 10.0)
        request.httpMethod = method

        // Add the access token to the request and then any custom headers
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        self.addCustomHeaders(request: &request, options: options)

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

                throw ErrorFactory.fromApiResponseError(
                    response: httpResponse,
                    data: data,
                    url: requestUrl.absoluteString)
            }

            // Return the response data on success
            return data

        } catch {

            throw ErrorFactory.fromApiRequestError(error: error, url: requestUrl.absoluteString)
        }
    }

    /*
     * Add custom headers to identify the calling UI to the API and enable log lookup
     */
    private func addCustomHeaders(request: inout URLRequest, options: ApiRequestOptions?) {

        request.addValue("BasicIosApp", forHTTPHeaderField: "x-mycompany-api-client")
        request.addValue(self.sessionId, forHTTPHeaderField: "x-mycompany-session-id")
        request.addValue(UUID().uuidString, forHTTPHeaderField: "x-mycompany-correlation-id")

        // A special header can be sent to thr API to cause a simulated exception
        if options != nil && options!.causeError {
            request.addValue("SampleApi", forHTTPHeaderField: "x-mycompany-test-exception")
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
