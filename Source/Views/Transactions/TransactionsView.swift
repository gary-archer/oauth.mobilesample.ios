import SwiftUI
import SwiftCoroutine

/*
 * The transactions view for a particular company
 */
struct TransactionsView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @EnvironmentObject private var eventBus: EventBus
    @ObservedObject private var model: TransactionsViewModel
    @ObservedObject private var viewRouter: ViewRouter

    init (model: TransactionsViewModel, viewRouter: ViewRouter) {

        self.model = model
        self.viewRouter = viewRouter
    }

    /*
     * Render the UI elements
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {

            // Render the heading
            if self.model.data != nil {
                Text("Today's Transactions for Company \(self.model.data!.id)")
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
                .listStyle(.plain)
            }
        }
        .onAppear(perform: self.initialLoad)
        .onReceive(self.eventBus.reloadMainViewTopic, perform: { data in
            self.handleReloadEvent(event: data)
        })
    }

    /*
     * Do the initial load
     */
    private func initialLoad() {
        self.loadData(causeError: false)
    }

    /*
     * Receive events
     */
    private func handleReloadEvent(event: ReloadMainViewEvent) {
        self.loadData(causeError: event.causeError)
    }

    /*
     * Load our data
     */
    private func loadData(causeError: Bool) {

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
        self.model.callApi(companyId: self.getCompanyId(), options: options, onError: onError)
    }

    /*
     * Get the current company id from the router
     */
    private func getCompanyId() -> String {

        if !self.viewRouter.params.isEmpty {
            if let companyId = self.viewRouter.params[0] as? String {
                return companyId
            }
        }

        return ""
    }
}
