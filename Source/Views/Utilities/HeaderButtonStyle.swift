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
    init (width: CGFloat, disabled: Bool? = false) {
        self.width = width
        self.disabled = disabled ?? false
    }

    /*
     * Apply custom styles for our button behaviour
     */
    func makeBody(configuration: Self.Configuration) -> some View {

        configuration.label
            .disabled(self.disabled)
            .frame(width: width, height: 60)
            .foregroundColor(Color.black)
            .background(Colors.lightBlue)
            .font(self.disabled ? disabledFont : enabledFont)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .cornerRadius(5)
    }
}
