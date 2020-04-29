import Foundation
import SwiftCoroutine

/*
 * Plumbing related to making HTTP calls
 */
class ApiClient {

    // Properties
    private var apiBaseUrl: URL
    private var authenticator: Authenticator
    let sessionId: String

    /*
     * Receive input
     */
    init(appConfiguration: AppConfiguration, authenticator: Authenticator) throws {

        guard let url = URL(string: appConfiguration.apiBaseUrl) else {
            throw ErrorHandler().fromMessage(message: "Invalid base URL received in API Client")
        }

        self.apiBaseUrl = url
        self.authenticator = authenticator
        self.sessionId = UUID().uuidString
    }

    /*
     * Make an API call to get user info
     */
    func getUserInfo() -> CoFuture<UserInfoClaims> {

        let promise = CoPromise<UserInfoClaims>()

        do {

            // Make the API call
            let data = try self.callApi(path: "userclaims/current", method: "GET").await()

            // Deserialize results
            let decoder = JSONDecoder()
            if let userInfo = try? decoder.decode(UserInfoClaims.self, from: data!) {
                promise.success(userInfo)
            } else {
                let error = ErrorHandler().fromMessage(message: "Unable to deserialize user info")
                promise.fail(error)
            }

        } catch {
            promise.fail(error)
        }

        return promise
    }

    /*
     * Make an API call to get companies
     */
    func getCompanies() -> CoFuture<[Company]> {

        let promise = CoPromise<[Company]>()

        do {

            // Make the API call
            let data = try self.callApi(path: "companies", method: "GET").await()

            // Deserialize results
            let decoder = JSONDecoder()
            if let companies = try? decoder.decode([Company].self, from: data!) {
                promise.success(companies)
            } else {
                let error = ErrorHandler().fromMessage(message: "Unable to deserialize companies")
                promise.fail(error)
            }

        } catch {
            promise.fail(error)
        }

        return promise
    }

    /*
     * Get the list of transactions for a company
     */
    func getCompanyTransactions(companyId: String) -> CoFuture<CompanyTransactions> {

        let promise = CoPromise<CompanyTransactions>()

        do {

            // Make the API call
            let data = try self.callApi(path: "companies/\(companyId)/transactions", method: "GET").await()

            // Deserialize results
            let decoder = JSONDecoder()
            if let transactions = try? decoder.decode(CompanyTransactions.self, from: data!) {
                promise.success(transactions)
            } else {
                let error = ErrorHandler().fromMessage(message: "Unable to deserialize transactions")
                promise.fail(error)
            }

        } catch {
            promise.fail(error)
        }

        return promise
    }

    /*
     * Do the HTTP plumbing to make the remote call
     */
    private func callApi(path: String, method: String) throws -> CoFuture<Data?> {

        let promise = CoPromise<Data?>()

        // Get the full URL
        let requestUrl = apiBaseUrl.appendingPathComponent(path)

        // Get the current access token
        var accessToken = try authenticator.getAccessToken()
            .await()

        do {
            // Call the API
            let data = try self.callApiWithToken(
                method: method,
                requestUrl: requestUrl,
                accessToken: accessToken)
                    .await()

            // Return the result to the caller
            promise.success(data)

        } catch {

            // Handle 401s specially
            let uiError = ErrorHandler().fromException(error: error)
            if uiError.statusCode == 401 {

                // Try to refresh the access token
                accessToken = try authenticator.refreshAccessToken()
                    .await()

                do {

                    // Call the API again with the new token
                    let data = try self.callApiWithToken(
                        method: method,
                        requestUrl: requestUrl,
                        accessToken: accessToken)
                            .await()

                    // Return the result to the caller
                    promise.success(data)

                } catch {

                    // Report errors on the retry
                    promise.fail(error)
                }
            }

            promise.fail(error)
        }

        return promise
    }

    /*
     * Make an async request for data
     */
    private func callApiWithToken(method: String, requestUrl: URL, accessToken: String) -> CoFuture<Data?> {

        let promise = CoPromise<Data?>()

        // Create the request object and set parameters
        var request = URLRequest(url: requestUrl, timeoutInterval: 10.0)
        request.httpMethod = method

        // Add the access token to the request and then any custom headers
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        self.addCustomHeaders(request: &request)

        // Create a data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            // Handle API request errors
            if let receivedError = error {
                let uiError = ErrorHandler().fromApiRequestError(
                    error: receivedError,
                    url: requestUrl.absoluteString)
                promise.fail(uiError)
            }

            // Get the response as an HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                let uiError = ErrorHandler().fromMessage(
                    message: "Invalid HTTP response object received after an API call")
                promise.fail(uiError)
                return
            }

            // Check for a successful status
            if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                let uiError = ErrorHandler().fromApiResponseError(
                    response: httpResponse,
                    data: data,
                    url: requestUrl.absoluteString)
                promise.fail(uiError)
                return
            }

            // Return the response data if applicable
            promise.success(data)
        }

        task.resume()
        return promise
    }

    /*
     * Add custom headers to identify the calling UI to the API and enable log lookup
     */
    private func addCustomHeaders(request: inout URLRequest) {

        request.addValue("BasicIosApp", forHTTPHeaderField: "x-mycompany-api-client")
        request.addValue(self.sessionId, forHTTPHeaderField: "x-mycompany-session-id")
        request.addValue(UUID().uuidString, forHTTPHeaderField: "x-mycompany-correlation-id")

        // A special header can be sent to thr API to cause a simulated exception
        // request.addValue("SampleApi", forHTTPHeaderField: "x-mycompany-test-exception")
    }
}
