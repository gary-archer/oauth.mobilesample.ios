import SwiftUI

/*
* A visual indication of how requests sent to the API are grouped
*/
struct SessionView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @EnvironmentObject private var eventBus: EventBus

    private let text: String
    @State private var isVisible: Bool

    init (sessionId: String) {
        self.text = "API Session Id: \(sessionId)"
        self.isVisible = false
    }

    /*
     * Render the UI elements
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width

        return VStack {

            if !self.isVisible {

                Text("")
                    .hidden()
                    .frame(height: 0)

            } else {

                Text(self.text)
                    .foregroundColor(Color.gray)
                    .fontWeight(.light)
                    .font(.system(size: 12))
                    .frame(maxWidth: deviceWidth, alignment: .trailing)
                    .padding(.trailing, 25)
            }
        }
        .onReceive(self.eventBus.navigatedTopic, perform: {data in
            self.handleNavigateEvent(event: data)
        })
    }

    /*
     * Receive events
     */
    private func handleNavigateEvent(event: NavigatedEvent) {
        self.isVisible = event.isMainView
    }
}
