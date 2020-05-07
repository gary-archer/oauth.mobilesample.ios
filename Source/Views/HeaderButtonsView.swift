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
               Text("Home").multilineTextAlignment(.center)
            }
            .buttonStyle(homeButtonStyle)

            // The reload button supports the long press event
            Button(action: self.onReloadPressed) {
                Text("Reload").multilineTextAlignment(.center)
            }
            .buttonStyle(sessionButtonStyle)
            .onLongPressGesture(minimumDuration: 2, perform: self.onReloadLongPressed)

            // A button to make the current access token act expired
            Button(action: self.onExpireAccessToken) {
                Text("Expire Access Token").multilineTextAlignment(.center)
            }
            .buttonStyle(sessionButtonStyle)

            // A button to make the current refresh token act expired
            Button(action: self.onExpireRefreshToken) {
                Text("Expire Refresh Token").multilineTextAlignment(.center)
            }
            .buttonStyle(sessionButtonStyle)

            // A button to initiate a logout
            Button(action: self.onLogout) {
                Text("Logout").multilineTextAlignment(.center)
            }
            .buttonStyle(sessionButtonStyle)
        }
    }

    /*
     * Normal reload clicks call the API normally
     */
    private func onReloadPressed() {
        self.onReloadData(false)
    }

    /*
     * The reload button can be used to simulate API errors and demonstrate supportability
     * If it is long clicked for 2 seconds or more then a custom header is sent to the cloud API
     */
    private func onReloadLongPressed() {
        self.onReloadData(true)
    }
}
