import SwiftUI
import SwiftCoroutine

/*
 * The transactions view for a particular company
 */
struct TransactionsView: View {

    // External objects
    @EnvironmentObject var reloadPublisher: ReloadPublisher
    @ObservedObject var viewRouter: ViewRouter

    // Properties
    private let viewManager: ViewManager
    private let apiClient: ApiClient
    private let totalWidth: CGFloat
    private let companyId: String

    // This view's state
    @State private var data: CompanyTransactions?
    @State private var error: UIError?

    /*
     * Initialise the view from input
     */
    init (
        viewRouter: ViewRouter,
        viewManager: ViewManager,
        apiClient: ApiClient,
        totalWidth: CGFloat) {

        // Store supplied values
        self.viewRouter = viewRouter
        self.viewManager = viewManager
        self.apiClient = apiClient
        self.totalWidth = totalWidth

        // Get the company from the router
        guard let companyId = viewRouter.params[0] as? String else {
            self.companyId = "0"
            return
        }

        self.companyId = companyId
    }

    /*
     * Render the view
     */
    var body: some View {

        VStack {

            // Render the heading
            Text("Today's Transactions for Company \(self.companyId)")
                .font(.headline)
                .frame(width: self.totalWidth)
                .padding()
                .background(Colors.lightBlue)

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

                    VStack {

                        HStack {
                            Text("Transaction Id")
                                .labelStyle()
                                .padding(.leading, 20)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                            Text(item.id)
                                .valueStyle()
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                        }.padding()

                        HStack {
                            Text("Investor Id")
                                .labelStyle()
                                .padding(.leading, 20)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                            Text(item.investorId)
                                .valueStyle()
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                        }.padding()

                        HStack {
                            Text("Amount USD")
                                .labelStyle()
                                .padding(.leading, 20)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                            Text(String(item.amountUsd))
                                .valueStyle(textColor: Colors.paleGreen)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                        }.padding()
                    }
                }
            }

        }.onAppear(perform: self.loadData)
         .onReceive(self.reloadPublisher.objectWillChange, perform: { _ in
             self.loadData()
         })
    }

    /*
     * Load our data
     */
    private func loadData() {

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {

                // Call the API to get transactions and update UI state
                self.viewManager.onMainViewLoading()
                self.data = try self.apiClient.getCompanyTransactions(companyId: self.companyId).await()
                self.viewManager.onMainViewLoaded()
                self.error = nil

            } catch {

                // Report errors and handle expected errors by error code
                let uiError = ErrorHandler().fromException(error: error)
                if uiError.statusCode == 404 && uiError.errorCode == ErrorCodes.companyNotFound {

                    // A deep link could provide an id such as 3, which is unauthorized
                    self.viewRouter.currentViewType = CompaniesView.Type.self
                    self.viewRouter.params = []

                } else if uiError.statusCode == 400 && uiError.errorCode == ErrorCodes.invalidCompanyId {

                    // A deep link could provide an invalid id value such as 'abc'
                    self.viewRouter.currentViewType = CompaniesView.Type.self
                    self.viewRouter.params = []

                } else {

                    // Handle unexpected errors
                    self.viewManager.onMainViewLoadFailed(error: uiError)
                    self.error = uiError
                }
            }
        }
    }
}
