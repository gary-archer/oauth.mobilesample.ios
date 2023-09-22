import Foundation

/*
 * Data and non UI logic for the companies view
 */
class CompaniesViewModel: ObservableObject {

    private let fetchClient: FetchClient
    private let viewModelCoordinator: ViewModelCoordinator

    @Published var companies = [Company]()
    @Published var error: UIError?

    /*
     * Receive global objects whenever the view is recreated
     */
    init(fetchClient: FetchClient, viewModelCoordinator: ViewModelCoordinator) {
        self.fetchClient = fetchClient
        self.viewModelCoordinator = viewModelCoordinator
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
        self.viewModelCoordinator.onMainViewModelLoading()
        self.error = nil

        Task {

            do {

                // Make the API call on a background thread
                let newCompanies = try await self.fetchClient.getCompanies(options: fetchOptions)
                await MainActor.run {

                    // Update state and notify
                    self.companies = newCompanies
                    self.viewModelCoordinator.onMainViewModelLoaded(cacheKey: fetchOptions.cacheKey)
                }

            } catch {

                await MainActor.run {

                    // Update state and notify
                    self.companies = [Company]()
                    self.error = ErrorFactory.fromException(error: error)
                    self.viewModelCoordinator.onMainViewModelLoaded(cacheKey: fetchOptions.cacheKey)
                }
            }
        }
    }
}
