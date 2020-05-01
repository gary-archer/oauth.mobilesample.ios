import SwiftUI

/*
 * Enable a custom style to be applied to a text view
 */
extension Text {

    /*
     * Style properties for labels
     */
    func labelStyle() -> Text {

        return foregroundColor(Color.gray)
                 .font(.system(size: 14))
                 .fontWeight(.semibold)
    }

    /*
     * Style properties for values
     */
    func valueStyle(textColor: Color = Color.black) -> Text {

        return foregroundColor(textColor)
                 .font(.system(size: 14))
                 .fontWeight(.semibold)
    }

    /*
     * Style properties for highlighted error fields
     */
    func errorStyle() -> Text {

        return foregroundColor(Color.red)
                 .font(.system(size: 14))
                 .fontWeight(.semibold)
    }
}
