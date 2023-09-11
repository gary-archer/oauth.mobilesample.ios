import SwiftUI

/*
 * Render an error field on its row
 */
struct ErrorDetailsItemView: View {

    private let errorLine: ErrorLine
    private let dialogWidth: CGFloat

    init(errorLine: ErrorLine, dialogWidth: CGFloat) {
        self.errorLine = errorLine
        self.dialogWidth = dialogWidth
    }

    /*
     * Render the error label and value
     */
    var body: some View {

        HStack(alignment: .top) {
            Text(self.errorLine.name)
                .labelStyle()
                .frame(width: self.dialogWidth / 3, alignment: .leading)
                .padding(.leading, self.dialogWidth / 12)

            Text(self.errorLine.value)
                .valueStyle(textColor: self.errorLine.valueColour)
                .frame(width: self.dialogWidth / 3, alignment: .leading)
                .padding(.leading, self.dialogWidth / 12)

        }.padding()
    }
}
