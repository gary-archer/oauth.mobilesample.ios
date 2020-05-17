import Foundation
import SwiftCoroutine

/*
 * Data and non UI logic for the companies view
 */
class CompaniesViewModel: ObservableObject {

    // Properties
    private let viewManager: ViewManager
    private let apiClient: ApiClient

    // Published state
    @Published var companies = [Company]()
    @Published var error: UIError?

    /*
     * Initialise from input
     */
    init (viewManager: ViewManager, apiClient: ApiClient) {
        self.viewManager = viewManager
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
                self.viewManager.onViewLoading()
                var newCompanies = [Company]()

                // Make the API call on a background thread and update state on success
                try DispatchQueue.global().await {
                    newCompanies = try self.apiClient.getCompanies(options: options).await()
                }

                // Update published properties on the main thread
                self.viewManager.onViewLoaded()
                self.companies = newCompanies

            } catch {

                // Update error state
                let uiError = ErrorHandler.fromException(error: error)
                self.companies = [Company]()
                self.error = uiError
                self.viewManager.onViewLoadFailed(error: uiError)
            }
        }
    }
}
