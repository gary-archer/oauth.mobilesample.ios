import SwiftUI
import SwiftCoroutine

/*
 * The transactions view for a particular company
 */
struct TransactionsView: View {

    // External objects
    @EnvironmentObject var dataReloadHandler: DataReloadHandler
    @ObservedObject var viewRouter: ViewRouter

    // Properties
    private let viewManager: ViewManager
    private let apiClient: ApiClient
    private let companyId: String

    // This view's state
    @State private var data: CompanyTransactions?
    @State private var error: UIError?

    /*
     * Initialise the view from input
     */
    init (viewRouter: ViewRouter, viewManager: ViewManager, apiClient: ApiClient) {

        // Store supplied values
        self.viewRouter = viewRouter
        self.viewManager = viewManager
        self.apiClient = apiClient

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

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {

            // Render the heading
            Text("Today's Transactions for Company \(self.companyId)")
                .font(.headline)
                .frame(width: deviceWidth)
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
                                .frame(width: deviceWidth / 3, alignment: .leading)
                                .padding(.leading, deviceWidth / 12)

                            Text(item.id)
                                .valueStyle()
                                .frame(width: deviceWidth / 3, alignment: .leading)
                                .padding(.leading, deviceWidth / 12)

                        }.padding()

                        HStack {
                            Text("Investor Id")
                                .labelStyle()
                                .frame(width: deviceWidth / 3, alignment: .leading)
                                .padding(.leading, deviceWidth / 12)

                            Text(item.investorId)
                                .valueStyle()
                                .frame(width: deviceWidth / 3, alignment: .leading)
                                .padding(.leading, deviceWidth / 12)

                        }.padding()

                        HStack {
                            Text("Amount USD")
                                .labelStyle()
                                .frame(width: deviceWidth / 3, alignment: .leading)
                                .padding(.leading, deviceWidth / 12)

                            Text(String(item.amountUsd))
                                .valueStyle(textColor: Colors.paleGreen)
                                .frame(width: deviceWidth / 3, alignment: .leading)
                                .padding(.leading, deviceWidth / 12)

                        }.padding()
                    }
                }
            }

        }.onAppear(perform: self.loadData)
         .onReceive(self.dataReloadHandler.objectWillChange, perform: { _ in
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

                // Reset state
                self.viewManager.onViewLoading()
                self.error = nil

                // Make the API call on a background thread
                try DispatchQueue.global().await {
                    self.data = try self.apiClient.getCompanyTransactions(companyId: self.companyId).await()
                }

                self.viewManager.onViewLoaded()

            } catch {

                // Handle the error
                let uiError = ErrorHandler().fromException(error: error)
                let isExpected = self.handleApiError(error: uiError)
                if isExpected {

                    // For 'expected' errors, return to the home view
                    self.viewManager.onViewLoaded()
                    self.viewRouter.currentViewType = CompaniesView.Type.self
                    self.viewRouter.params = []

                } else {

                    self.viewManager.onViewLoadFailed(error: uiError)
                    self.error = uiError
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
