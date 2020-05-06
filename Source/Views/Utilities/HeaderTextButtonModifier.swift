import SwiftUI

/*
* A custom style for long pressable buttons, which we implement as a text control
*/
struct HeaderTextButtonModifier: ViewModifier {

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
    * Apply custom styles for our text button behaviour
    */
    func body(content: Content) -> some View {
        content

        .disabled(self.disabled)
        .frame(width: self.width, height: 60)
        .foregroundColor(Color.black)
        .background(Colors.lightBlue)
        .font(self.disabled ? disabledFont : enabledFont)
        .scaleEffect(1.0)
        .cornerRadius(5)
        .multilineTextAlignment(.center)
    }
}
