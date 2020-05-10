import SwiftUI

/*
 * The header buttons that control session behaviour
 */
struct HeaderButtonsView: View {

    // External objects
    @EnvironmentObject var dataReloadHandler: DataReloadHandler
    @GestureState private var reloadTapped = false

    // Properties
    private var sessionButtonsDisabled: Bool
    private let onHome: () -> Void
    private let onReloadData: (Bool) -> Void
    private let onExpireAccessToken: () -> Void
    private let onExpireRefreshToken: () -> Void
    private let onLogout: () -> Void

    /*
     * Set properties from input and note that to store callbacks we need to mark them as @escaping
     */
    init (
        sessionButtonsEnabled: Bool,
        onHome: @escaping () -> Void,
        onReloadData: @escaping (Bool) -> Void,
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
        let homeButtonStyle = HeaderButtonStyle(width: deviceWidth / 6, disabled: false)
        let sessionButtonStyle = HeaderButtonStyle(width: deviceWidth / 6, disabled: self.sessionButtonsDisabled)

        return HStack {

            // A button to navigate home
            Button(action: self.onHome) {
               Text("Home")
            }
                .buttonStyle(homeButtonStyle)

            // The reload button also support a long press event
            Button(action: self.onReloadDefaultAction) {
                Text("Reload")
            }
                .buttonStyle(sessionButtonStyle)
                .disabled(self.sessionButtonsDisabled)
                .modifier(LongPressModifier(
                    isDisabled: self.sessionButtonsDisabled,
                    completionHandler: self.onReloadPressed))

            // A button to make the current access token act expired
            Button(action: self.onExpireAccessToken) {
                Text("Expire Access Token").multilineTextAlignment(.center)
            }
                .buttonStyle(sessionButtonStyle)
                .disabled(self.sessionButtonsDisabled)

            // A button to make the current refresh token act expired
            Button(action: self.onExpireRefreshToken) {
                Text("Expire Refresh Token").multilineTextAlignment(.center)
            }
                .buttonStyle(sessionButtonStyle)
                .disabled(self.sessionButtonsDisabled)

            // A button to initiate a logout
            Button(action: self.onLogout) {
                Text("Logout")
            }
                .buttonStyle(sessionButtonStyle)
                .disabled(self.sessionButtonsDisabled)
        }
    }

    /*
     * The default action for the reload button is overridden so that it does nothing
     */
    private func onReloadDefaultAction() {
    }

    /*
     * Reload clicks are handled via the LongPressModifier which returns a boolean result
     */
    private func onReloadPressed(isLongPress: Bool) {
        self.onReloadData(isLongPress)
    }
}
