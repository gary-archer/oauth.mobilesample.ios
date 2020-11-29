import SwiftUI

/*
 * The home view to show a list of companies
 */
struct CompaniesView: View {

    @ObservedObject private var model: CompaniesViewModel
    @ObservedObject private var viewRouter: ViewRouter
    @EnvironmentObject private var orientationHandler: OrientationHandler
    @EnvironmentObject private var dataReloadHandler: DataReloadHandler

    init (model: CompaniesViewModel, viewRouter: ViewRouter) {
        self.model = model
        self.viewRouter = viewRouter
    }

    /*
     * Render the body and handle click events
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {

            // Show the header
            Text("Company List")
                .font(.headline)
                .frame(width: deviceWidth)
                .padding()
                .background(Colors.lightBlue)

            // Render errors getting data if required
            if self.model.error != nil {
                ErrorSummaryView(
                    hyperlinkText: "Problem Encountered in Companies View",
                    dialogTitle: "Companies View Error",
                    error: self.model.error!)
                        .padding(.top)
            }

            // Render the companies list
            if self.model.companies.count > 0 {
                List(self.model.companies, id: \.id) { item in
                    CompanyItemView(viewRouter: self.viewRouter, company: item)
                }
            }
        }
        .onAppear(perform: self.initialLoad)
        .onReceive(self.dataReloadHandler.objectWillChange, perform: {causeError in
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
     * Ask the model to call the API to get data
     */
    private func loadData(causeError: Bool) {
        let options = ApiRequestOptions(causeError: causeError)
        self.model.callApi(options: options)
    }
}
