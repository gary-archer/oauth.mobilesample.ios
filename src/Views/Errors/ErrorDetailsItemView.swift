import SwiftUI

/*
 * Render an error field on its row
 */
struct ErrorDetailsItemView: View {

    private let errorField: ErrorField
    private let dialogWidth: CGFloat

    init(errorField: ErrorField, dialogWidth: CGFloat) {
        self.errorField = errorField
        self.dialogWidth = dialogWidth
    }

    /*
     * Render the error label and value
     */
    var body: some View {

        HStack(alignment: .top) {
            Text(LocalizedStringKey(self.errorField.name))
                .labelStyle()
                .frame(width: self.dialogWidth / 3, alignment: .leading)
                .padding(.leading, self.dialogWidth / 12)

            Text(self.errorField.value)
                .valueStyle(textColor: self.errorField.valueColour)
                .frame(width: self.dialogWidth / 3, alignment: .leading)
                .padding(.leading, self.dialogWidth / 12)

        }.padding()
    }
}
