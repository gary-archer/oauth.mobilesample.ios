import SwiftUI

/*
 * A custom style for our header buttons
 */
struct HeaderButtonStyle: ButtonStyle {

    // Properties
    private let width: CGFloat
    private var disabled: Bool
    private let enabledFont = Font.system(.caption).weight(.regular)
    private let disabledFont = Font.system(.caption).weight(.thin)

    /*
     * Set values from input
     */
    init (width: CGFloat, disabled: Bool) {
        self.width = width
        self.disabled = disabled
    }

    /*
     * Apply custom styles to the button label
     */
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {

        configuration.label
            .frame(width: self.width, height: 60)
            .foregroundColor(Color.black)
            .background(Colors.lightBlue)
            .font(self.disabled ? disabledFont : enabledFont)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .cornerRadius(5)
    }
}
