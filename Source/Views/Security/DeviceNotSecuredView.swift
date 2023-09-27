import SwiftUI

/*
* Rendered when the user's device is not secured with a opasscode
*/
struct DeviceNotSecuredView: View {

    @EnvironmentObject private var eventBus: EventBus

    /*
     * Render the UI elements
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width

        return VStack {

            Text("device_not_secured_message")
                .valueStyle()
                .padding()

            Text("device_secured_message")
                .valueStyle()
                .padding()

            Button(action: self.onOpenSystemSettings) {
               Text("open_device_settings")
                   .padding()
            }
                .foregroundColor(Color.black)
                .background(Color.green)
                .font(.system(size: 16))
                .cornerRadius(5)
                .frame(width: deviceWidth, height: 60)
        }
        .onAppear(perform: self.initialLoad)
    }

    /*
     * Open system settings, so that the user can select Touch Id & Passcode
     */
    func onOpenSystemSettings() {

        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(settingsUrl)
    }

    /*
     * Handler the initial load
     */
    private func initialLoad() {
        self.eventBus.sendNavigatedEvent(isMainView: false)
    }
}
