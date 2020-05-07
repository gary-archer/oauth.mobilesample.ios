import SwiftUI

/*
 * A modifier that we can apply to a button to make it handle both normal clicks and long clicks
 */
struct LongPressModifier: ViewModifier {

    // Mutable state
    @State private var startTime: Date?

    // Properties
    private let isDisabled: Bool
    private let longPressSeconds: Double
    private let completionHandler: (Bool) -> Void

    /*
     * Initialise long press behaviour to 2 seconds
     */
    init(isDisabled: Bool, completionHandler: @escaping (Bool) -> Void) {

        self.isDisabled = isDisabled
        self.longPressSeconds = 2.0
        self.completionHandler = completionHandler
    }

    /*
     * Capture the start and end times, running a timer
     */
    func body(content: Content) -> some View {

        content.simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in

                if self.isDisabled {
                    return
                }

                // Record the start time at the time we are clicked
                if self.startTime == nil {
                    self.startTime = Date()
                }
            }
            .onEnded { _ in

                if self.isDisabled {
                    return
                }

                // Measure the time elapsed and reset
                let endTime = Date()
                let interval = self.startTime!.distance(to: endTime)
                self.startTime = nil

                // Return a boolean indicating whether a normal or long press
                let isLongPress = !interval.isLess(than: self.longPressSeconds)
                self.completionHandler(isLongPress)
            })
    }
}
