import SwiftUI

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

            // Render errors when applicable
            if self.model.error != nil {
                ErrorSummaryView(
                    error: self.model.error!,
                    hyperlinkText: "Problem Encountered in Transactions View",
                    dialogTitle: "Transactions View Error",
                    padding: EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
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
        .onReceive(self.eventBus.reloadDataTopic, perform: { data in
            self.handleReloadEvent(event: data)
        })
    }

    /*
     * Do the initial load
     */
    private func initialLoad() {
        self.eventBus.sendNavigatedEvent(isMainView: true)
        self.loadData()
    }

    /*
     * Receive events
     */
    private func handleReloadEvent(event: ReloadDataEvent) {
        let options = ViewLoadOptions(forceReload: true, causeError: event.causeError)
        self.loadData(options: options)
    }

    /*
     * Load our data
     */
    private func loadData(options: ViewLoadOptions? = nil) {

        // For forbidden errors we navigate back to the home view
        let onForbidden: () -> Void = {

            self.viewRouter.changeMainView(
                newViewType: CompaniesView.Type.self,
                newViewParams: []
            )
        }

        // Ask the model to call the API and update its state, which is then published to update the view
        self.model.callApi(companyId: self.getCompanyId(), options: options, onForbidden: onForbidden)
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
