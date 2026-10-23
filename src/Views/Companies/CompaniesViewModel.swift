import Foundation

/*
 * Data and non UI logic for the companies view
 */
class CompaniesViewModel: ObservableObject {

    private let fetchClient: FetchClient
    private let apiRequestCoordinator: ApiRequestCoordinator

    @Published var companies = [Company]()
    @Published var error: UIError?

    /*
     * Receive global objects whenever the view is recreated
     */
    init(fetchClient: FetchClient, apiRequestCoordinator: ApiRequestCoordinator) {
        self.fetchClient = fetchClient
        self.apiRequestCoordinator = apiRequestCoordinator
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ViewLoadOptions? = nil) {

        let fetchOptions = FetchOptions(
            cacheKey: FetchCacheKeys.Companies,
            forceReload: options?.forceReload ?? false,
            causeError: options?.causeError ?? false)

        // Initialise state
        self.apiRequestCoordinator.onApiRequestStart(cacheKeys: fetchOptions.cacheKey)
        self.error = nil

        Task {

            do {

                // Make the API call on a background thread
                let companies = try await self.fetchClient.getCompanies(options: fetchOptions)
                await MainActor.run {

                    // Update state and notify
                    if companies != nil {
                        self.companies = companies!
                    }
                    self.apiRequestCoordinator.onApiRequestEnd()
                }

            } catch {

                await MainActor.run {

                    // Update state and notify
                    self.companies = [Company]()
                    self.error = ErrorFactory.fromException(error: error)
                    self.apiRequestCoordinator.onApiRequestEnd()
                }
            }
        }
    }
}
