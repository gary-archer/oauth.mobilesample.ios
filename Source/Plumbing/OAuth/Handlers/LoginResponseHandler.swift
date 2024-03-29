import AppAuth

/*
 * A utility to manage Swift async await compatibility
 */
class LoginResponseHandler {

    var storedContinuation: CheckedContinuation<OIDAuthorizationResponse, Error>?

    /*
     * An async method to wait for the login response to return
     */
    func waitForCallback() async throws -> OIDAuthorizationResponse {

        try await withCheckedThrowingContinuation { continuation in
            storedContinuation = continuation
        }
    }

    /*
     * A callback that can be supplied to MainActor.run when triggering a login redirect
     */
    func callback(response: OIDAuthorizationResponse?, error: Error?) {

        if error != nil {
            storedContinuation?.resume(throwing: error!)
        } else {
            storedContinuation?.resume(returning: response!)
        }
    }
}
