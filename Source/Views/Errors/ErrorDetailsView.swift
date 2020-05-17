import SwiftUI

/*
 * A view to show error details in a modal dialog
 */
struct ErrorDetailsView: View {

    // This enables us to dismiss the sheet
    @Environment(\.presentationMode) var presentationMode

    // Properties
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
                        .frame(width: geometry.size.width * 0.9)
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

                    VStack {

                        HStack(alignment: .top) {
                            Text(item.name)
                                .labelStyle()
                                .frame(width: geometry.size.width / 3, alignment: .leading)
                                .padding(.leading, geometry.size.width / 12)

                            Text(item.value)
                                .valueStyle(textColor: item.name == "Instance Id" ? Color.red : Color.black)
                                .frame(width: geometry.size.width / 3, alignment: .leading)
                                .padding(.leading, geometry.size.width / 12)

                        }.padding()
                    }
                }

            }.contentShape(Rectangle())
        }
    }
}
