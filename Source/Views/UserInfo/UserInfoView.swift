import SwiftUI
import SwiftUITooltip

/*
 * The user info view
 */
struct UserInfoView: View {

    @EnvironmentObject private var eventBus: EventBus
    @ObservedObject private var model: UserInfoViewModel
    @State var isTooltipVisible = false
    private var tooltipConfig = DefaultTooltipConfig()

    init (model: UserInfoViewModel) {

        // Store a reference to the model
        self.model = model

        // Configure the user info tooltip
        self.tooltipConfig = DefaultTooltipConfig()
        self.tooltipConfig.side = TooltipSide.bottom
        self.tooltipConfig.arrowHeight = 0
        self.tooltipConfig.arrowWidth = 0
        self.tooltipConfig.backgroundColor = Color.gray
        self.tooltipConfig.borderRadius = 4
    }

    /*
     * Render user info details based on state
     */
    var body: some View {

        return VStack {

            // Render the user name
            Text(self.model.getUserName())
                .frame(width: 150, alignment: .trailing)
                .font(.system(size: 14))
                .onTapGesture {

                    // Render a tooltip for 2 seconds with further user info when the name is clicked
                    self.isTooltipVisible = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.isTooltipVisible = false
                    }
                }
                .tooltip(self.isTooltipVisible, config: self.tooltipConfig) {

                    VStack {
                        Text(self.model.getUserTitle())
                            .font(.system(size: 12))
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .frame(width: 150, alignment: .center)

                        Text(self.model.getUserRegions())
                            .font(.system(size: 12))
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .frame(width: 150, alignment: .center)
                    }
                }

            // Render errors when applicable
            if self.model.error != nil {
                ErrorSummaryView(
                    error: self.model.error!,
                    hyperlinkText: "userinfo_error_hyperlink",
                    dialogTitle: "userinfo_error_dialogtitle",
                    padding: EdgeInsets(top: -10, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .onReceive(self.eventBus.navigatedTopic, perform: {data in
            self.handleNavigateEvent(event: data)
        })
        .onReceive(self.eventBus.reloadDataTopic, perform: { data in
            self.handleReloadDataEvent(event: data)
        })
    }

    /*
     * Load data when the main view is navigated to
     */
    private func handleNavigateEvent(event: NavigatedEvent) {

        if event.isMainView {

            // Load user data the first time
            self.loadData()

        } else {

            // Clear data when in the logged out view
            self.model.clearData()
        }
   }

    /*
     * Handle reload events
     */
    private func handleReloadDataEvent(event: ReloadDataEvent) {
        let options = ViewLoadOptions(forceReload: true, causeError: event.causeError)
        self.loadData(options: options)
    }

    /*
     * Ask the model to call the API to get data
     */
    private func loadData(options: ViewLoadOptions? = nil) {
        self.model.callApi(options: options)
    }
}
