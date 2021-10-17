import SwiftUI

/*
 * A view to show error details in a modal dialog
 */
struct ErrorDetailsView: View {

    @Environment(\.presentationMode) private var presentationMode
    private let error: UIError
    private let dialogTitle: String
    private let errorLines: [ErrorLine]

    /*
     * Initialise data
     */
    init (dialogTitle: String, error: UIError) {
        self.error = error
        self.dialogTitle = dialogTitle
        self.errorLines = ErrorFormatter.getErrorLines(error: self.error)
    }

    /*
     * Render the view
     */
    var body: some View {

        GeometryReader { geometry in

            VStack {

                HStack(spacing: 0) {

                    // Render the title
                    Text(self.dialogTitle)
                        .font(.headline)
                        .frame(width: geometry.size.width * 0.8)
                        .padding()
                        .background(Colors.lightBlue)

                    // Render a close button to the right
                    Text("X")
                        .frame(width: geometry.size.width * 0.1, alignment: .leading)
                        .padding()
                        .background(Colors.lightBlue)
                        .onTapGesture {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                }

                // Show each error field on a row as a label / value pair
                List(self.errorLines, id: \.name) { item in
                    ErrorDetailsItemView(errorLine: item, dialogWidth: geometry.size.width)
                }

            }.contentShape(Rectangle())
        }
    }
}
