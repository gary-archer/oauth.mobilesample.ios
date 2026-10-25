/*
 * Manages global view model objects for the React application
 */
class ViewModelStore {

    private let fetchClient: FetchClient
    private let apiRequestCoordinator: ApiRequestCoordinator
    private let eventBus: EventBus

    private var companiesViewModel: CompaniesViewModel?
    private var transactionsViewModel: TransactionsViewModel?
    private var userInfoViewModel: UserInfoViewModel?

    init(
        fetchClient: FetchClient,
        apiRequestCoordinator: ApiRequestCoordinator,
        eventBus: EventBus) {

        self.fetchClient = fetchClient
        self.apiRequestCoordinator = apiRequestCoordinator
        self.eventBus = eventBus
    }

    /*
     * Create the companies view model on first use
     */
    func getCompaniesViewModel() -> CompaniesViewModel {

        if self.companiesViewModel == nil {

            self.companiesViewModel = CompaniesViewModel(
                fetchClient: self.fetchClient,
                apiRequestCoordinator: self.apiRequestCoordinator)
        }

        return self.companiesViewModel!
    }

    /*
     * Create the transactions view model on first use
     */
    func getTransactionsViewModel() -> TransactionsViewModel {

        if self.transactionsViewModel == nil {

            self.transactionsViewModel = TransactionsViewModel(
                fetchClient: self.fetchClient,
                apiRequestCoordinator: self.apiRequestCoordinator)
        }

        return self.transactionsViewModel!
    }

    /*
     * Create the user info view model on first use
     */
    func getUserInfoViewModel() -> UserInfoViewModel {

        if self.userInfoViewModel == nil {
            self.userInfoViewModel = UserInfoViewModel(
                fetchClient: self.fetchClient,
                apiRequestCoordinator: self.apiRequestCoordinator)
        }

        return self.userInfoViewModel!
    }
}
