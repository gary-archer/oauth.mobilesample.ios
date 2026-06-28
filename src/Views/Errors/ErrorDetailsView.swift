import SwiftUI

/*
 * A view to show error details in a modal dialog
 */
struct ErrorDetailsView: View {

    @Environment(\.presentationMode) private var presentationMode
    private let error: UIError
    private let dialogTitle: String
    private let errorFields: [ErrorField]

    /*
     * Initialise data
     */
    init (dialogTitle: String, error: UIError) {
        self.error = error
        self.dialogTitle = dialogTitle
        self.errorFields = ErrorFormatter.getErrorFields(error: self.error)
    }

    /*
     * Render the view
     */
    var body: some View {

        GeometryReader { geometry in

            VStack {

                HStack(spacing: 0) {

                    // Render the title
                    Text(LocalizedStringKey(self.dialogTitle))
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
                List(self.errorFields, id: \.name) { item in
                    ErrorDetailsItemView(errorField: item, dialogWidth: geometry.size.width)
                }
                .listStyle(.plain)

            }.contentShape(Rectangle())
        }
    }
}
