import Foundation

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
    func callApi(options: ViewLoadOptions? = nil, onError: @escaping (UIError) -> Void) {

        let fetchOptions = ApiRequestOptions(causeError: options?.causeError ?? false)

        self.apiViewEvents.onViewLoading(name: ApiViewNames.Main)
        Task {

            do {

                // Make the API call on a background thread
                let newCompanies = try await self.apiClient.getCompanies(options: fetchOptions)
                await MainActor.run {

                    // Update published properties on the main thread
                    self.apiViewEvents.onViewLoaded(name: ApiViewNames.Main)
                    self.companies = newCompanies
                }

            } catch {

                await MainActor.run {

                    // Update state and report the error
                    self.companies = [Company]()
                    let uiError = ErrorFactory.fromException(error: error)
                    onError(uiError)
                    self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.Main, error: uiError)
                }
            }
        }
    }
}
