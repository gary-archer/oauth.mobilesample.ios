import SwiftUI

/*
 * A view to show an error summary hyperlink
 */
struct ErrorSummaryView: View {

    @EnvironmentObject private var eventBus: EventBus
    @State private var showModal: Bool
    @State private var error: UIError

    private let hyperlinkText: String
    private let dialogTitle: String
    private let padding: EdgeInsets

    init(
        error: UIError,
        hyperlinkText: String,
        dialogTitle: String,
        padding: EdgeInsets

    ) {
        self.error = error
        self.hyperlinkText = hyperlinkText
        self.dialogTitle = dialogTitle
        self.padding = padding
        self.showModal = false
    }

    /*
     * Render the view
     */
    var body: some View {

        VStack {

            // Show a hidden control when there is an expected error
            if self.error.errorCode == ErrorCodes.loginRequired {

                Text("")
                    .hidden()
                    .frame(height: 0)

            } else {

                Text(LocalizedStringKey(self.hyperlinkText))
                    .errorStyle()
                    .contentShape(Rectangle())
                    .padding(self.padding)
                    .sheet(isPresented: self.$showModal) {

                        // Render the error details view in a modal sheet when the link is clicked
                        ErrorDetailsView(dialogTitle: self.dialogTitle, error: self.error)
                    }
                    .onTapGesture {
                        self.showModal = true
                    }
            }

        }
    }
}
