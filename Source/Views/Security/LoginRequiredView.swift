import SwiftUI

/*
* Rendered when the user needs to log in
*/
struct LoginRequiredView: View {

    @EnvironmentObject private var eventBus: EventBus

    /*
     * Render the UI elements
     */
    var body: some View {

        return VStack {
            Text("logged_out_message")
        }.onAppear(perform: self.initialLoad)
    }

    /*
     * Handler the initial load
     */
    private func initialLoad() {
        self.eventBus.sendNavigatedEvent(isMainView: false)
    }
}
