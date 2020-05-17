import SwiftUI
import SwiftCoroutine

/*
 * The transactions view for a particular company
 */
struct TransactionsView: View {

    @ObservedObject var viewRouter: ViewRouter
    @ObservedObject var model: TransactionsViewModel
    @EnvironmentObject var orientationHandler: OrientationHandler
    @EnvironmentObject var dataReloadHandler: DataReloadHandler

    /*
     * Initialise the view from input
     */
    init (viewRouter: ViewRouter, viewManager: ViewManager, apiClient: ApiClient) {

        self.viewRouter = viewRouter
        self.model = TransactionsViewModel(viewManager: viewManager, apiClient: apiClient)

        // Get the supplied company id when we first navigate here
        if let companyId = viewRouter.params[0] as? String {
            self.model.companyId = companyId
        }
    }

    /*
     * Render the view
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {

            // Render the heading
            if !self.model.companyId.isEmpty {
                Text("Today's Transactions for Company \(self.model.companyId)")
                    .font(.headline)
                    .frame(width: deviceWidth)
                    .padding()
                    .background(Colors.lightBlue)
            }

            // Render errors getting data if required
            if self.model.error != nil {
                ErrorSummaryView(
                    hyperlinkText: "Problem Encountered in Transactions View",
                    dialogTitle: "Transactions View Error",
                    error: self.model.error!)
                        .padding(.top)
            }

            // Render the transactions list if we can retrieve it
            if self.model.data != nil && self.model.data!.transactions.count > 0 {
                List(self.model.data!.transactions, id: \.id) { item in
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
            self.model.companyId = companyId
        }

        // For expected errors we navigate back to the home view
        let onError: (Bool) -> Void = { isExpected in
            if isExpected {
                self.viewRouter.changeMainView(
                    newViewType: CompaniesView.Type.self,
                    newViewParams: []
                )
            }
        }

        // Ask the model to call the API
        let options = ApiRequestOptions(causeError: causeError)
        self.model.callApi(options: options, onError: onError)
    }
}
