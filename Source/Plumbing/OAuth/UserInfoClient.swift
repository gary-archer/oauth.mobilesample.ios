import Foundation

class UserInfoClient {

    private let configuration: OAuthConfiguration
    private let authenticator: Authenticator

    init (configuration: OAuthConfiguration, authenticator: Authenticator) {
        self.configuration = configuration
        self.authenticator = authenticator
    }

    func getUserInfo() async throws -> OAuthUserInfo {

        // Get the current access token
        var accessToken = try await self.authenticator.getAccessToken()

        do {
            // Call the user info endpoint with the current token
            return try await self.makeUserInfoRequest(accessToken: accessToken)

        } catch {

            // Handle 401s specially
            let uiError = ErrorFactory.fromException(error: error)
            if uiError.statusCode == 401 {

                // Try to refresh the access token
                accessToken = try await self.authenticator.refreshAccessToken()

                // Call the user info endpoint again with the new token
                return try await self.makeUserInfoRequest(accessToken: accessToken)
            }

            throw error
        }
    }

    /*
     * Make a user info request with the current access token
     */
    private func makeUserInfoRequest(accessToken: String) async throws -> OAuthUserInfo {

        guard let userInfoEndpoint = URL(string: self.configuration.userInfoEndpoint) else {
            throw ErrorFactory.fromMessage(message: "Invalid user info URL configured")
        }

        // Create the request object and set parameters
        var request = URLRequest(url: userInfoEndpoint, timeoutInterval: 10.0)
        request.httpMethod = "GET"

        // Add the access token to the request
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Send the request and get the response
        do {

            let (data, response) = try await URLSession.shared.data(for: request)

            // Get the response as an HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {

                throw ErrorFactory.fromMessage(
                    message: "Invalid HTTP response object received after a user info call")
            }

            // Check for a successful status
            if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {

                throw ErrorFactory.fromHttpResponseError(
                    response: httpResponse,
                    data: data,
                    url: self.configuration.userInfoEndpoint)
            }

            // Return the response data on success
            var givenName  = ""
            var familyName = ""
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) {

                if let fields = json as? [String: Any] {
                    givenName = fields["given_name"] as? String ?? ""
                    familyName = fields["family_name"] as? String ?? ""
                }
            }

            return OAuthUserInfo(givenName: givenName, familyName: familyName)

        } catch {

            throw ErrorFactory.fromApiRequestError(error: error, url: self.configuration.userInfoEndpoint)
        }
    }
}
