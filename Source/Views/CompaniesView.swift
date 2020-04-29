import SwiftUI
import SwiftCoroutine

/*
* The home view to show a list of companies
*/
struct CompaniesView: View {

    // External objects
    @ObservedObject var viewRouter: ViewRouter
    @EnvironmentObject var reloadPublisher: ReloadPublisher

    // Properties
    private let viewManager: ViewManager
    private let apiClient: ApiClient
    private let totalWidth: CGFloat

    // This view's state
    @State private var companies = [Company]()
    @State private var error: UIError?

    /*
     * Initialise from input
     */
    init (
        viewRouter: ViewRouter,
        viewManager: ViewManager,
        apiClient: ApiClient,
        totalWidth: CGFloat) {

        self.viewRouter = viewRouter
        self.viewManager = viewManager
        self.apiClient = apiClient
        self.totalWidth = totalWidth
    }

    /*
     * Render the body and handle click events
     */
    var body: some View {

        VStack {

            // Show the header
            Text("Company List")
                .font(.headline)
                .frame(width: self.totalWidth)
                .padding()
                .background(Colors.lightBlue)

            // Render errors getting data if required
            if self.error != nil {
                ErrorSummaryView(
                    hyperlinkText: "Problem Encountered in Companies View",
                    dialogTitle: "Companies View Error",
                    error: self.error!)
            }

            // Render the companies list if we can retrieve it
            if companies.count > 0 {

                List(companies, id: \.id) { item in

                    VStack {

                        HStack {
                            Image(String(item.id))
                                .padding(.leading, 20)
                                .frame(width: self.totalWidth / 2, height: 0, alignment: .leading)

                            Text(item.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(width: self.totalWidth / 2, alignment: .leading)
                        }.padding()

                        HStack {
                            Text("Target USD")
                                .labelStyle()
                                .padding(.leading, 20)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                            Text(self.formatAmount(value: item.targetUsd))
                                .valueStyle(textColor: Colors.paleGreen)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                        }.padding()

                        HStack {
                            Text("Investment USD")
                                .labelStyle()
                                .padding(.leading, 20)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                            Text(self.formatAmount(value: item.investmentUsd))
                                .valueStyle(textColor: Colors.paleGreen)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                        }.padding()

                        HStack {
                            Text("# Investors")
                                .labelStyle()
                                .padding(.leading, 20)
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                            Text(String(item.noInvestors))
                                .valueStyle()
                                .frame(width: self.totalWidth / 2, alignment: .leading)

                        }.padding()

                    }.contentShape(Rectangle())
                     .onTapGesture {
                        self.moveToTransactions(id: item.id)
                    }
                }
            }

        }.onAppear(perform: self.loadData)
         .onReceive(self.reloadPublisher.objectWillChange, perform: { _ in
             self.loadData()
         })
    }

    /*
     * When a company is clicked, move to the transactions view and indicate which item
     */
    private func moveToTransactions(id: Int) {
        self.viewRouter.currentViewType = TransactionsView.Type.self
        self.viewRouter.params = [String(id)]
    }

    /*
     * Call the API to get data
     */
    private func loadData() {

        // Run async operations in a coroutine
        DispatchQueue.main.startCoroutine {

            do {

                // Make the API call and update UI state
                self.viewManager.onMainViewLoading()
                self.companies = try self.apiClient.getCompanies().await()
                self.viewManager.onMainViewLoaded()
                self.error = nil

            } catch {

                // Report errors
                let uiError = ErrorHandler().fromException(error: error)
                self.viewManager.onMainViewLoadFailed(error: uiError)
                self.error = uiError
            }
        }
    }

    /*
     * Format an amount field to include thousands separators
     */
    private func formatAmount(value: Int) -> String {
        return String(format: "%.0f", locale: Locale.current, Double(value))
    }
}
