import SwiftUI

/*
* Rendered when the user's device is not secured with a opasscode
*/
struct DeviceNotSecuredView: View {

    /*
     * Render the view
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width

        return VStack {

            Text("Please configure a Passcode so that your data is secure")
                .valueStyle()
                .padding(.bottom)

            Text("Once complete, return here and click the HOME button")
                .valueStyle()
                .padding(.bottom)

            Button(action: self.onOpenSystemSettings) {
               Text("Open Settings / Touch ID & Passcode")
                    .multilineTextAlignment(.center)
                    .padding()
            }
                .foregroundColor(Color.black)
                .background(Color.green)
                .font(.system(size: 16))
                .cornerRadius(5)
                .frame(width: deviceWidth, height: 60)
        }
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
}
