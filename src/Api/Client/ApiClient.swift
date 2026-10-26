import Foundation

/*
 * An example API client that implements infrastructure to fetch  and cache sensitive data
 */
class ApiClient {

    private var configuration: Configuration
    private var fetchCache: FetchCache
    private var oauthClient: OAuthClient
    private var requestCoordinator: ApiRequestCoordinator

    init(
        configuration: Configuration,
        oauthClient: OAuthClient,
        eventBus: EventBus) throws {

        self.configuration = configuration
        self.fetchCache = FetchCache()
        self.oauthClient = oauthClient
        self.requestCoordinator = ApiRequestCoordinator(eventBus: eventBus)
    }

    /*
     * Make an API call to get companies
     */
    func getCompanies(options: GetOptions) async throws -> [Company]? {

        guard let url = URL(string: "\(self.configuration.app.apiBaseUrl)/companies") else {
            throw ErrorFactory.fromMessage(message: "Invalid API URL in ApiClient")
        }

        // Make the API call
        let data = try await self.getDataFromApi(url: url, options: options)
        if data == nil {
            return nil
        }

        // Deserialize and return data
        return try self.deserialize(data: data!)
    }

    /*
     * Get the list of transactions for a company
     */
    func getCompanyTransactions(
        companyId: String,
        options: GetOptions) async throws -> CompanyTransactions? {

        guard let url = URL(string: "\(self.configuration.app.apiBaseUrl)/companies/\(companyId)/transactions") else {
            throw ErrorFactory.fromMessage(message: "Invalid API URL in ApiClient")
        }

        // Make the API call
        let data = try await self.getDataFromApi(url: url, options: options)
        if data == nil {
            return nil
        }

        // Deserialize and return data
        return try self.deserialize(data: data!)
    }

    /*
     * Download user attributes from the authorization server
     */
    func getOAuthUserInfo(options: GetOptions) async throws -> OAuthUserInfo? {

        guard let url = URL(string: self.configuration.oauth.userInfoEndpoint) else {
            throw ErrorFactory.fromMessage(message: "Invalid user info endpoint in ApiClient")
        }

        // Make the API call
        let data = try await self.getDataFromApi(url: url, options: options)
        if data == nil {
            return nil
        }

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
    func getApiUserInfo(options: GetOptions) async throws -> ApiUserInfo? {

        guard let url = URL(string: "\(self.configuration.app.apiBaseUrl)/userinfo") else {
            throw ErrorFactory.fromMessage(message: "Invalid API URL in ApiClient")
        }

        // Make the API call
        let data = try await self.getDataFromApi(url: url, options: options)
        if data == nil {
            return nil
        }

        // Deserialize and return data
        return try self.deserialize(data: data!)
    }

    /*
     * Return the overall status after a batch of concurrent API requests complete
     */
    func hasErrors() -> Bool {
        return self.requestCoordinator.hasErrors()
    }

    /*
     * Clear any API state when the user logs out
     */
    func clearLoginState() {
        self.fetchCache.clearAll()
        self.requestCoordinator.resetState()
    }

    /*
     * Make a GET request and deal with caching
     */
    private func getDataFromApi(url: URL, options: GetOptions) async throws -> Data? {

        // Remove the item from the cache when a reload is requested
        if options.forceReload {
            self.fetchCache.removeItem(key: options.cacheKey)
        }

        // Return existing data from the memory cache when available
        var cacheItem = self.fetchCache.getItem(key: options.cacheKey)
        if cacheItem != nil {
            return cacheItem!.getData()
        }

        // Create the cache item with a null value, so that any additional view requests return null
        cacheItem = self.fetchCache.createItem(key: options.cacheKey)

        // Notify the request coordinator on the main thread that we are sending an API request
        await MainActor.run {
            self.requestCoordinator.onApiRequestStart()
        }

        do {

            // Call the API and return data on success
            let data = try await self.callApiWithTokenRefresh(url: url, jsonData: nil, causeError: options.causeError)
            cacheItem!.setData(value: data)

            // Notify the request coordinator on the main thread that we sent an API request
            await MainActor.run {
                self.requestCoordinator.onApiRequestEnd()
            }

            return data

        } catch {
            
            // Make sure we clear the item from the cache
            self.fetchCache.removeItem(key: options.cacheKey);

            // Handle the error and notify the request coordinator that the API request failed
            let uiError = ErrorFactory.fromException(error: error)
            await MainActor.run {
                self.requestCoordinator.onApiRequestEnd(error: uiError)
            }
            throw uiError
        }
    }

    /*
     * Make a GET request and deal with caching
     */
    private func callApiWithTokenRefresh(
        url: URL,
        jsonData: Data?,
        causeError: Bool = false) async throws -> Data? {

        // Avoid API requests when there is no access token, and instead trigger a login
        var accessToken = self.oauthClient.getAccessToken()
        if accessToken == nil {
            throw ErrorFactory.fromLoginRequired()
        }

        do {
            // Call the API and return data on success
            return try await self.callApiWithToken(
                method: "GET",
                url: url,
                jsonData: nil,
                accessToken: accessToken!,
                causeError: causeError)

        } catch {

            // Report errors if this is not a 401
            let error1 = ErrorFactory.fromException(error: error)
            if error1.statusCode != 401 {
                throw error1
            }

            // Try to refresh the access token
            accessToken = try await self.oauthClient.synchronizedRefreshAccessToken()

            do {

                // Call the API and return data on success
                return try await self.callApiWithToken(
                    method: "GET",
                    url: url,
                    jsonData: nil,
                    accessToken: accessToken!,
                    causeError: causeError)

            } catch {

                // Save retry errors
                let error2 = ErrorFactory.fromException(error: error)
                if error2.statusCode != 401 {
                    throw error2
                }

                // A permanent API 401 error triggers a new login.
                // This could be caused by an invalid API configuration.
                self.oauthClient.clearLoginState()
                throw ErrorFactory.fromLoginRequired()
            }
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
        causeError: Bool) async throws -> Data? {

        // Create the request object and set parameters
        var request = URLRequest(url: url, timeoutInterval: 10.0)
        request.httpMethod = method

        // Add the access token to the request and then any custom headers
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Add other headers
        request.addValue(UUID().uuidString, forHTTPHeaderField: "correlation-id")

        // If required, add a header to request that an API simulates a 500 exception
        if causeError {
            request.addValue("FinalApi", forHTTPHeaderField: "api-exception-simulation")
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
