import SwiftUI

/*
 * The header buttons that control session behaviour
 */
struct HeaderButtonsView: View {

    // External objects
    @EnvironmentObject var dataReloadHandler: DataReloadHandler

    // Properties
    private var sessionButtonsDisabled: Bool
    private let onHome: () -> Void
    private let onReloadData: () -> Void
    private let onExpireAccessToken: () -> Void
    private let onExpireRefreshToken: () -> Void
    private let onLogout: () -> Void

    /*
     * Set properties from input and note that to store callbacks we need to mark them as @escaping
     */
    init (
        sessionButtonsEnabled: Bool,
        onHome: @escaping () -> Void,
        onReloadData: @escaping () -> Void,
        onExpireAccessToken: @escaping () -> Void,
        onExpireRefreshToken: @escaping () -> Void,
        onLogout: @escaping () -> Void) {

        self.sessionButtonsDisabled = !sessionButtonsEnabled
        self.onHome = onHome
        self.onReloadData = onReloadData
        self.onExpireAccessToken = onExpireAccessToken
        self.onExpireRefreshToken = onExpireRefreshToken
        self.onLogout = onLogout
    }

    /*
     * Render the buttons with click handlers and an enabled state
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return HStack {

            // Inform the parent view when the home button is clicked
            Button(action: self.onHome) {
               Text("Home").multilineTextAlignment(.center)
            }.buttonStyle(HeaderButtonStyle(width: deviceWidth / 6))

            // Inform the parent view when a data reload is requested
            Button(action: self.onReloadPressed) {
                Text("Reload").multilineTextAlignment(.center)
            }
            .disabled(self.sessionButtonsDisabled)
            .buttonStyle(
                HeaderButtonStyle(width: deviceWidth / 6, disabled: self.sessionButtonsDisabled))

            // Initiate a test operation to make the access token act expired
            Button(action: self.onExpireAccessToken) {
                Text("Expire Access Token").multilineTextAlignment(.center)
            }
            .disabled(self.sessionButtonsDisabled)
            .buttonStyle(
                HeaderButtonStyle(width: deviceWidth / 6, disabled: self.sessionButtonsDisabled))

            // Initiate a test operation to make the refresh token act expired
            Button(action: self.onExpireRefreshToken) {
                Text("Expire Refresh Token").multilineTextAlignment(.center)
            }
            .disabled(self.sessionButtonsDisabled)
            .buttonStyle(
                HeaderButtonStyle(width: deviceWidth / 6, disabled: self.sessionButtonsDisabled))

            // Initiate a logout operation
            Button(action: self.onLogout) {
                Text("Logout").multilineTextAlignment(.center)
            }
            .disabled(self.sessionButtonsDisabled)
            .buttonStyle(
                HeaderButtonStyle(width: deviceWidth / 6, disabled: self.sessionButtonsDisabled))
        }
    }

    /*
     * Normal reload clicks call the API normally
     */
    private func onReloadPressed() {

        dataReloadHandler.causeError = false
        self.onReloadData()
    }

    /*
     * The reload button can be used to simulate API errors and demonstrate supportability
     * If it is long clicked for 2 seconds or more then a custom header is sent to the cloud API
     */
    private func onReloadLongPressed() {

        dataReloadHandler.causeError = true
        self.onReloadData()
    }
}
