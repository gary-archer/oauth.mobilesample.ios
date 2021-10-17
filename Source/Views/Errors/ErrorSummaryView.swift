import SwiftUI

/*
 * A view to show an error summary hyperlink
 */
struct ErrorSummaryView: View {

    private let hyperlinkText: String
    private let dialogTitle: String
    private let error: UIError?
    @State private var showModal = false

    /*
     * Initialise data
     */
    init (
        hyperlinkText: String,
        dialogTitle: String,
        error: UIError) {

        self.hyperlinkText = hyperlinkText
        self.dialogTitle = dialogTitle
        self.error = error
    }

    /*
     * Render the view
     */
    var body: some View {

        VStack {

            // Show a hidden control when there is no error to display
            if self.error == nil || self.error!.errorCode == ErrorCodes.loginRequired {

                Text("")
                    .hidden()
                    .frame(height: 0)

            } else {

                // Display an error hyperlink when there are error details
                Text(self.hyperlinkText)
                    .errorStyle()
                    .contentShape(Rectangle())
                    .sheet(isPresented: self.$showModal) {

                        // Render the error details view in a modal sheet when the link is clicked
                        ErrorDetailsView(dialogTitle: self.dialogTitle, error: self.error!)
                    }
                    .onTapGesture {
                        self.showModal = true
                    }
            }
        }
    }
}
