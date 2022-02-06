import Foundation
import SwiftCoroutine

/*
 * Data and non UI logic for the companies view
 */
class CompaniesViewModel: ObservableObject {

    // Late created properties
    private let apiClient: ApiClient
    private let apiViewEvents: ApiViewEvents

    // Published state
    @Published var companies = [Company]()

    /*
     * Receive global objects whenever the view is recreated
     */
    init(apiClient: ApiClient, apiViewEvents: ApiViewEvents) {
        self.apiClient = apiClient
        self.apiViewEvents = apiViewEvents
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ApiRequestOptions, onError: @escaping (UIError) -> Void) {

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {
                // Initialise for this request
                self.apiViewEvents.onViewLoading(name: ApiViewNames.Main)
                var newCompanies = [Company]()

                // Make the API call on a background thread and update state on success
                try DispatchQueue.global().await {
                    newCompanies = try self.apiClient.getCompanies(options: options).await()
                }

                // Update published properties on the main thread
                self.apiViewEvents.onViewLoaded(name: ApiViewNames.Main)
                self.companies = newCompanies

            } catch {

                // Update state and report the error
                self.companies = [Company]()
                let uiError = ErrorFactory.fromException(error: error)
                onError(uiError)
                self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.Main, error: uiError)
            }
        }
    }
}
