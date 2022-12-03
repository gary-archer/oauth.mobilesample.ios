import Foundation

/*
 * Data and non UI logic for the transactions view
 */
class TransactionsViewModel: ObservableObject {

    // Late created properties
    private let apiClient: ApiClient
    private let apiViewEvents: ApiViewEvents

    // Published state
    @Published var data: CompanyTransactions?

    /*
     * Receive global objects whenever the view is recreated
     */
    init(apiClient: ApiClient, apiViewEvents: ApiViewEvents) {
        self.apiViewEvents = apiViewEvents
        self.apiClient = apiClient
    }

    /*
     * Do the work of calling the API
     */
    func callApi(
        companyId: String,
        options: ApiRequestOptions,
        onError: @escaping (Bool, UIError) -> Void) {

        Task {

            do {

                // Make the API call on a background thread
                self.apiViewEvents.onViewLoading(name: ApiViewNames.Main)
                let newData = try await self.apiClient.getCompanyTransactions(companyId: companyId, options: options)

                await MainActor.run {

                    // Update published properties on the main thread
                    self.data = newData
                    self.apiViewEvents.onViewLoaded(name: ApiViewNames.Main)
                }

            } catch {

                await MainActor.run {

                    // Handle the error
                    self.data = nil

                    // If this is a real error we update error state
                    let uiError = ErrorFactory.fromException(error: error)
                    let isExpected = self.handleApiError(error: uiError)
                    if !isExpected {
                        self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.Main, error: uiError)
                    }

                    // Inform the view
                    onError(isExpected, uiError)
                }
            }
        }
    }

    /*
     * Handle 'business errors' received from the API
     */
    private func handleApiError(error: UIError) -> Bool {

        var isExpected = false

        if error.statusCode == 404 && error.errorCode == ErrorCodes.companyNotFound {

            // A deep link could provide an id such as 3, which is unauthorized
            isExpected = true

        } else if error.statusCode == 400 && error.errorCode == ErrorCodes.invalidCompanyId {

            // A deep link could provide an invalid id value such as 'abc'
            isExpected = true
        }

        return isExpected
    }
}
