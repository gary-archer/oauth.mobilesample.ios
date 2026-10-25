/*
 * Manages global view model objects for the React application
 */
class ViewModelStore {

    private let apiClient: ApiClient
    private let eventBus: EventBus

    private var companiesViewModel: CompaniesViewModel?
    private var transactionsViewModel: TransactionsViewModel?
    private var userInfoViewModel: UserInfoViewModel?

    init(apiClient: ApiClient, eventBus: EventBus) {

        self.apiClient = apiClient
        self.eventBus = eventBus
    }

    /*
     * Create the companies view model on first use
     */
    func getCompaniesViewModel() -> CompaniesViewModel {

        if self.companiesViewModel == nil {
            self.companiesViewModel = CompaniesViewModel(apiClient: self.apiClient)
        }

        return self.companiesViewModel!
    }

    /*
     * Create the transactions view model on first use
     */
    func getTransactionsViewModel() -> TransactionsViewModel {

        if self.transactionsViewModel == nil {

            self.transactionsViewModel = TransactionsViewModel(apiClient: self.apiClient)
        }

        return self.transactionsViewModel!
    }

    /*
     * Create the user info view model on first use
     */
    func getUserInfoViewModel() -> UserInfoViewModel {

        if self.userInfoViewModel == nil {
            self.userInfoViewModel = UserInfoViewModel(apiClient: self.apiClient)
        }

        return self.userInfoViewModel!
    }
}
