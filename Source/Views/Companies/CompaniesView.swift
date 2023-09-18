import SwiftUI

/*
 * The home view to show a list of companies
 */
struct CompaniesView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @EnvironmentObject private var eventBus: EventBus
    @ObservedObject private var model: CompaniesViewModel
    @ObservedObject private var viewRouter: ViewRouter

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

            // Render errors when applicable
            if self.model.error != nil {
                ErrorSummaryView(
                    error: self.model.error!,
                    hyperlinkText: "Problem Encountered in Companies View",
                    dialogTitle: "Companies View Error",
                    padding: EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            }

            // Render the companies list
            if self.model.companies.count > 0 {
                List(self.model.companies, id: \.id) { item in
                    CompanyItemView(viewRouter: self.viewRouter, company: item)
                }
                .listStyle(.plain)
            }
        }
        .onAppear(perform: self.initialLoad)
        .onReceive(self.eventBus.reloadMainViewTopic, perform: {data in
            self.handleReloadData(event: data)
        })
    }

    /*
     * Receive events
     */
    private func handleReloadData(event: ReloadMainViewEvent) {
        let options = ViewLoadOptions(forceReload: true, causeError: event.causeError)
        self.loadData(options: options)
    }

    /*
     * Do the initial load
     */
    private func initialLoad() {
        self.eventBus.sendNavigatedEvent(isMainView: true)
        self.loadData()
    }

    /*
     * Ask the model to call the API to get data
     */
    private func loadData(options: ViewLoadOptions? = nil) {

        // Clear error state before calling the API and handle errors afterwards if there is failure
        self.eventBus.sendSetErrorEvent(containingViewName: "companies", error: nil)
        let onError: () -> Void = {
            self.eventBus.sendSetErrorEvent(containingViewName: "companies", error: self.model.error!)
        }

        // Ask the model to call the API and update its state, which is then published to update the view
        self.model.callApi(options: options, onError: onError)
    }
}
