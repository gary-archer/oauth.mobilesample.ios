import Foundation
import Combine

/*
 * An object to ensure that the layout is redrawn when there is a change in device orientation
 * Include this as an environment object in any views that need to be redrawn
 * https://stackoverflow.com/questions/57441654/swiftui-repaint-view-components-on-device-rotationhange
 */
class OrientationHandler: ObservableObject {

    @Published var isLandscape: Bool = false
}
