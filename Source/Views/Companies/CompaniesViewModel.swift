import Foundation
import SwiftCoroutine

/*
 * Data and non UI logic for the companies view
 */
class CompaniesViewModel: ObservableObject {

    // Late created properties
    private var apiViewEvents: ApiViewEvents?
    private var apiClient: ApiClient?

    // Published state
    @Published var companies = [Company]()
    @Published var error: UIError?

    /*
     * Set objects once they have been created
     */
    func initialise(apiViewEvents: ApiViewEvents, apiClient: ApiClient) {
        self.apiViewEvents = apiViewEvents
        self.apiClient = apiClient
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ApiRequestOptions) {

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {
                // Initialise for this request
                self.error = nil
                self.apiViewEvents!.onViewLoading(name: ApiViewNames.Main)
                var newCompanies = [Company]()

                // Make the API call on a background thread and update state on success
                try DispatchQueue.global().await {
                    newCompanies = try self.apiClient!.getCompanies(options: options).await()
                }

                // Update published properties on the main thread
                self.apiViewEvents!.onViewLoaded(name: ApiViewNames.Main)
                self.companies = newCompanies

            } catch {

                // Update error state
                let uiError = ErrorHandler.fromException(error: error)
                self.companies = [Company]()
                self.error = uiError
                self.apiViewEvents!.onViewLoadFailed(name: ApiViewNames.Main, error: uiError)
            }
        }
    }
}
