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
            Text("You are logged out - click HOME to sign in ...")
        }.onAppear(perform: self.initialLoad)
    }

    /*
     * Handler the initial load
     */
    private func initialLoad() {
        print("Login required navigated")
        self.eventBus.sendNavigatedEvent(isMainView: false)
    }
}
