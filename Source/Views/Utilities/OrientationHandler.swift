import Foundation
import Combine

/*
 * An object to ensure that the layout is redrawn when there is a change in device orientation
 */
final class OrientationHandler: ObservableObject {

    let objectWillChange = PassthroughSubject<(), Never>()

    /*
     * The app view depends on this environment object, so it is redrawn when there is an orientation change
     // https://stackoverflow.com/questions/57441654/swiftui-repaint-view-components-on-device-rotationhange
     */
    func sendViewUpdateEvent() {
        objectWillChange.send()
    }
}
