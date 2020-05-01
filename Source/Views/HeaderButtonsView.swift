import SwiftUI

/*
 * The header buttons that control session behaviour
 */
struct HeaderButtonsView: View {

    // The router object
    @ObservedObject var viewRouter: ViewRouter

    // Properties
    private var sessionButtonsDisabled: Bool
    private let screenWidth: CGFloat

    // Callbacks invoked when buttons are clicked
    private let onHome: () -> Void
    private let onReloadData: () -> Void
    private let onExpireAccessToken: () -> Void
    private let onExpireRefreshToken: () -> Void
    private let onLogout: () -> Void

    /*
     * Set properties from input and note that to store callbacks we need to mark them as @escaping
     */
    init (
        viewRouter: ViewRouter,
        sessionButtonsEnabled: Bool,
        onHome: @escaping () -> Void,
        onReloadData: @escaping () -> Void,
        onExpireAccessToken: @escaping () -> Void,
        onExpireRefreshToken: @escaping () -> Void,
        onLogout: @escaping () -> Void) {

        self.viewRouter = viewRouter
        self.sessionButtonsDisabled = !sessionButtonsEnabled
        self.screenWidth = UIScreen.main.bounds.size.width

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

        HStack {

            // Inform the parent view when the home button is clicked
            Button(action: self.onHome) {
               Text("Home").multilineTextAlignment(.center)
            }.buttonStyle(HeaderButtonStyle(width: self.screenWidth / 6))

            // Inform the parent view when a data reload is requested
            Button(action: self.onReloadData) {
                Text("Reload").multilineTextAlignment(.center)
            }
            .disabled(self.sessionButtonsDisabled)
            .buttonStyle(
                HeaderButtonStyle(width: self.screenWidth / 6, disabled: self.sessionButtonsDisabled))

            // Initiate a test operation to make the access token act expired
            Button(action: self.onExpireAccessToken) {
                Text("Expire Access Token").multilineTextAlignment(.center)
            }
            .disabled(self.sessionButtonsDisabled)
            .buttonStyle(
                HeaderButtonStyle(width: self.screenWidth / 6, disabled: self.sessionButtonsDisabled))

            // Initiate a test operation to make the refresh token act expired
            Button(action: self.onExpireRefreshToken) {
                Text("Expire Refresh Token").multilineTextAlignment(.center)
            }
            .disabled(self.sessionButtonsDisabled)
            .buttonStyle(
                HeaderButtonStyle(width: self.screenWidth / 6, disabled: self.sessionButtonsDisabled))

            // Initiate a logout operation
            Button(action: self.onLogout) {
                Text("Logout").multilineTextAlignment(.center)
            }
            .disabled(self.sessionButtonsDisabled)
            .buttonStyle(
                HeaderButtonStyle(width: self.screenWidth / 6, disabled: self.sessionButtonsDisabled))
        }
    }
}
