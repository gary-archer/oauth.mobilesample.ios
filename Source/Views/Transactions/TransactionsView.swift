import SwiftUI

/*
 * The transactions view for a particular company
 */
struct TransactionsView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @EnvironmentObject private var eventBus: EventBus
    @ObservedObject private var model: TransactionsViewModel
    @ObservedObject private var viewRouter: ViewRouter

    private let title: String

    init (model: TransactionsViewModel, viewRouter: ViewRouter) {

        self.model = model
        self.viewRouter = viewRouter

        var companyId = ""
        if !viewRouter.params.isEmpty {
            if let id = viewRouter.params[0] as? String {
                companyId = id
            }
        }

        self.title = String.localizedStringWithFormat(
            NSLocalizedString("transactions_title", comment: ""), companyId)

        self.model.setCompanyId(companyId: companyId)
    }

    /*
     * Render the UI elements
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {

            // Render the heading
            if self.model.data != nil {
                Text(self.title)
                    .font(.headline)
                    .frame(width: deviceWidth)
                    .padding()
                    .background(Colors.lightBlue)
            }

            // Render errors when applicable
            if self.model.error != nil {
                ErrorSummaryView(
                    error: self.model.error!,
                    hyperlinkText: "transactions_error_hyperlink",
                    dialogTitle: "transactions_error_dialogtitle",
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

        if !viewRouter.params.isEmpty {
            if let id = viewRouter.params[0] as? String {
                self.model.setCompanyId(companyId: id)
            }
        }

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
        self.model.callApi(options: options, onForbidden: onForbidden)
    }
}
