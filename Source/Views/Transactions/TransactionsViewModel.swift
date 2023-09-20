import Foundation

/*
 * Data and non UI logic for the transactions view
 */
class TransactionsViewModel: ObservableObject {

    // Late created properties
    private let fetchClient: FetchClient
    private let apiViewEvents: ApiViewEvents
    private var companyId: String?

    // Published state
    @Published var data: CompanyTransactions?
    @Published var error: UIError?

    /*
     * Receive global objects whenever the view is recreated
     */
    init(fetchClient: FetchClient, apiViewEvents: ApiViewEvents) {
        self.apiViewEvents = apiViewEvents
        self.fetchClient = fetchClient
        self.companyId = nil
    }

    /*
     * Do the work of calling the API
     */
    func callApi(
        companyId: String,
        options: ViewLoadOptions? = nil,
        onForbidden: @escaping () -> Void) {

        let fetchOptions = FetchOptions(causeError: options?.causeError ?? false)

        self.apiViewEvents.onViewLoading(name: ApiViewNames.Main)
        self.companyId = companyId
        self.error = nil

        Task {

            do {

                // Make the API call on a background thread
                let newData = try await self.fetchClient.getCompanyTransactions(
                    companyId: companyId,
                    options: fetchOptions)

                await MainActor.run {

                    // Update published properties on the main thread
                    self.data = newData
                    self.apiViewEvents.onViewLoaded(name: ApiViewNames.Main)
                }

            } catch {

                await MainActor.run {

                    // Handle the error
                    self.data = nil
                    if self.isForbiddenError() {

                        // Inform the view to take an action when access is forbidden
                        onForbidden()

                    } else {

                        // Otherwise update error state
                        self.error = ErrorFactory.fromException(error: error)
                        self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.Main, error: self.error!)
                    }
                }
            }
        }
    }

    /*
     * Handle 'business errors' received from the API
     */
    private func isForbiddenError() -> Bool {

        if self.error != nil {

            if self.error!.statusCode == 404 && self.error!.errorCode == ErrorCodes.companyNotFound {

                // A deep link could provide an id such as 3, which is unauthorized
                return true

            } else if self.error!.statusCode == 400 && self.error!.errorCode == ErrorCodes.invalidCompanyId {

                // A deep link could provide an invalid id value such as 'abc'
                return true
            }
        }

        return false
    }
}
