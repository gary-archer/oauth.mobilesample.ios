import SwiftUI

/*
 * A view to show an error summary hyperlink
 */
struct ErrorSummaryView: View {

    @EnvironmentObject private var eventBus: EventBus
    @State private var showModal: Bool
    @State private var error: UIError?

    private let containingViewName: String
    private let hyperlinkText: String
    private let dialogTitle: String
    private let padding: EdgeInsets

    init(
        containingViewName: String,
        hyperlinkText: String,
        dialogTitle: String,
        padding: EdgeInsets

    ) {
        self.containingViewName = containingViewName
        self.hyperlinkText = hyperlinkText
        self.dialogTitle = dialogTitle
        self.padding = padding

        self.showModal = false
        self.error = nil
    }

    /*
     * Render the view
     */
    var body: some View {

        VStack {

            // Show a hidden control when there is no error to display
            if self.error == nil {

                Text("")
                    .hidden()
                    .frame(height: 0)

            } else {

                Text(self.hyperlinkText)
                    .errorStyle()
                    .contentShape(Rectangle())
                    .padding(self.padding)
                    .sheet(isPresented: self.$showModal) {

                        // Render the error details view in a modal sheet when the link is clicked
                        ErrorDetailsView(dialogTitle: self.dialogTitle, error: self.error!)
                    }
                    .onTapGesture {
                        self.showModal = true
                    }
            }

        }.onReceive(self.eventBus.setErrorEventTopic, perform: { data in
            self.handleSetErrorEvent(event: data)
        })
    }

    /*
     * Receive the event that populates error data and causes it to render
     */
    private func handleSetErrorEvent(event: SetErrorEvent) {

        // Ensure that the error is for this instance of the error summary view
        if self.containingViewName == event.containingViewName {

            if event.error == nil {

                // Clear previous error details before retrying an operation
                self.error = nil

            } else {

                // Set details unless this is an ignored error, to terminate failed API calls
                if event.error!.errorCode != ErrorCodes.loginRequired {
                    self.error = event.error
                }
            }
        }
    }
}
