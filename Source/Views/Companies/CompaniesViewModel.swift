import Foundation

/*
 * Data and non UI logic for the companies view
 */
class CompaniesViewModel: ObservableObject {

    // Late created properties
    private let fetchClient: FetchClient
    private let apiViewEvents: ApiViewEvents

    // Published state
    @Published var companies = [Company]()
    @Published var error: UIError?

    /*
     * Receive global objects whenever the view is recreated
     */
    init(fetchClient: FetchClient, apiViewEvents: ApiViewEvents) {
        self.fetchClient = fetchClient
        self.apiViewEvents = apiViewEvents
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ViewLoadOptions? = nil) {

        let fetchOptions = FetchOptions(causeError: options?.causeError ?? false)

        self.apiViewEvents.onViewLoading(name: ApiViewNames.Main)
        self.error = nil

        Task {

            do {

                // Make the API call on a background thread
                let newCompanies = try await self.fetchClient.getCompanies(options: fetchOptions)
                await MainActor.run {

                    // Update published properties on the main thread
                    self.apiViewEvents.onViewLoaded(name: ApiViewNames.Main)
                    self.companies = newCompanies
                }

            } catch {

                await MainActor.run {

                    // Update state and report the error
                    self.companies = [Company]()
                    self.error = ErrorFactory.fromException(error: error)
                    self.apiViewEvents.onViewLoadFailed(name: ApiViewNames.Main, error: self.error!)
                }
            }
        }
    }
}
