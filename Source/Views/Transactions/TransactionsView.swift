import SwiftUI
import SwiftCoroutine

/*
 * The transactions view for a particular company
 */
struct TransactionsView: View {

    // External objects
    @EnvironmentObject var orientationHandler: OrientationHandler
    @EnvironmentObject var dataReloadHandler: DataReloadHandler
    @ObservedObject var viewRouter: ViewRouter

    // Properties
    private let viewManager: ViewManager
    private let apiClient: ApiClient

    // Mutable state
    @State private var companyId: String = ""
    @State private var data: CompanyTransactions?
    @State private var error: UIError?

    /*
     * Initialise the view from input
     */
    init (viewRouter: ViewRouter, viewManager: ViewManager, apiClient: ApiClient) {

        self.viewRouter = viewRouter
        self.viewManager = viewManager
        self.apiClient = apiClient

        // Get the supplied company id when we first navigate here
        if let companyId = viewRouter.params[0] as? String {
            self._companyId = State(initialValue: companyId)
        }
    }

    /*
     * Render the view
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {

            // Render the heading
            if !self.companyId.isEmpty {
                Text("Today's Transactions for Company \(self.companyId)")
                    .font(.headline)
                    .frame(width: deviceWidth)
                    .padding()
                    .background(Colors.lightBlue)
            }

            // Render errors getting data if required
            if self.error != nil {
                ErrorSummaryView(
                    hyperlinkText: "Problem Encountered in Transactions View",
                    dialogTitle: "Transactions View Error",
                    error: self.error!)
                        .padding(.top)
            }

            // Render the transactions list if we can retrieve it
            if self.data != nil && self.data!.transactions.count > 0 {
                List(self.data!.transactions, id: \.id) { item in
                    TransactionItemView(transaction: item)
                }
            }
        }
        .onAppear(perform: self.initialLoad)
        .onReceive(self.dataReloadHandler.objectWillChange, perform: { causeError in
            self.loadData(causeError: causeError)
        })
    }

    /*
     * Do the initial load
     */
    private func initialLoad() {
        self.loadData(causeError: false)
    }

    /*
     * Load our data
     */
    private func loadData(causeError: Bool) {

        // Update to the latest router value, since we can navigate to this view while it is already active
        // If viewing company 1 transactions and we deep link to company 2, this will force an update to 2
        if let companyId = viewRouter.params[0] as? String {
            self.companyId = companyId
        }

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {

                // Initialise for this request
                self.error = nil
                let options = ApiRequestOptions(causeError: causeError)

                // Make the API call on a background thread
                self.viewManager.onViewLoading()
                try DispatchQueue.global().await {

                    self.data = try self.apiClient.getCompanyTransactions(
                        companyId: self.companyId,
                        options: options)
                            .await()
                }
                self.viewManager.onViewLoaded()

            } catch {

                // Handle the error
                let uiError = ErrorHandler.fromException(error: error)
                let isExpected = self.handleApiError(error: uiError)
                if isExpected {

                    // For 'expected' errors, return to the home view
                    self.viewManager.onViewLoaded()
                    self.viewRouter.changeMainView(
                        newViewType: CompaniesView.Type.self,
                        newViewParams: [])

                } else {

                    self.data = nil
                    self.error = uiError
                    self.viewManager.onViewLoadFailed(error: uiError)
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
