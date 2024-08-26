import Foundation

/*
 * Data and non UI logic for the transactions view
 */
class TransactionsViewModel: ObservableObject {

    // Late created properties
    private let fetchClient: FetchClient
    private let viewModelCoordinator: ViewModelCoordinator
    var companyId: String?
    private var companyWasChanged: Bool

    // Published state
    @Published var data: CompanyTransactions?
    @Published var error: UIError?

    /*
     * Receive global objects whenever the view is recreated
     */
    init(fetchClient: FetchClient, viewModelCoordinator: ViewModelCoordinator) {

        self.viewModelCoordinator = viewModelCoordinator
        self.fetchClient = fetchClient
        self.companyId = nil
        self.companyWasChanged = false
    }

    /*
     * Allow the company ID to be updated during navigation
     */
    func setCompanyId(companyId: String) {

        if companyId != self.companyId {
            self.companyWasChanged = true
        }

        self.companyId = companyId
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: ViewLoadOptions? = nil, onForbidden: @escaping () -> Void) {

        let fetchOptions = FetchOptions(
            cacheKey: "\(FetchCacheKeys.Transactions)-\(self.companyId!)",
            forceReload: options?.forceReload ?? false,
            causeError: options?.causeError ?? false)

        // Initialise state
        self.viewModelCoordinator.onMainViewModelLoading()
        self.error = nil

        // Handle deep link updates to the company ID
        if self.companyWasChanged {
            self.data = nil
            self.companyWasChanged = false
        }

        Task {

            do {

                // Make the API call on a background thread
                let transactions = try await self.fetchClient.getCompanyTransactions(
                    companyId: self.companyId!,
                    options: fetchOptions)

                await MainActor.run {

                    // Update state and notify
                    if transactions != nil {
                        self.data = transactions
                    }
                    self.viewModelCoordinator.onMainViewModelLoaded(cacheKey: fetchOptions.cacheKey)
                }

            } catch {

                await MainActor.run {

                    // Handle the error
                    self.data = nil
                    let uiError = ErrorFactory.fromException(error: error)
                    if self.isForbiddenError(uiError: uiError) {

                        // Inform the view to take an action when access is forbidden
                        onForbidden()

                    } else {

                        // Otherwise update state and notify
                        self.error = uiError
                        self.viewModelCoordinator.onMainViewModelLoaded(cacheKey: fetchOptions.cacheKey)
                    }
                }
            }
        }
    }

    /*
     * Handle 'business errors' received from the API
     */
    private func isForbiddenError(uiError: UIError) -> Bool {

        if uiError.statusCode == 404 && uiError.errorCode == ErrorCodes.companyNotFound {

            // A deep link could provide an id such as 3, which is unauthorized
            return true

        } else if uiError.statusCode == 400 && uiError.errorCode == ErrorCodes.invalidCompanyId {

            // A deep link could provide an invalid id value such as 'abc'
            return true
        }

        return false
    }
}
