import SwiftUI

/*
 * The header buttons that control session behaviour
 */
struct HeaderButtonsView: View {

    @EnvironmentObject private var eventBus: EventBus
    @State private var hasData = false
    @State private var homeTitle = NSLocalizedString("home_button", comment: "")
    @GestureState private var reloadTapped = false

    private let onHome: () -> Void
    private let onReloadData: (Bool) -> Void
    private let onExpireAccessToken: () -> Void
    private let onExpireRefreshToken: () -> Void
    private let onLogout: () -> Void

    /*
     * To store callbacks we need to mark them as @escaping
     */
    init (
        onHome: @escaping () -> Void,
        onReloadData: @escaping (Bool) -> Void,
        onExpireAccessToken: @escaping () -> Void,
        onExpireRefreshToken: @escaping () -> Void,
        onLogout: @escaping () -> Void) {

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
        let sessionButtonsDisabled = !self.hasData
        let sessionButtonStyle = HeaderButtonStyle(width: deviceWidth / 6, disabled: sessionButtonsDisabled)

        return HStack {

            // A button to navigate home
            Button(action: self.onHome) {
                Text(homeTitle)
            }
                .buttonStyle(homeButtonStyle)

            // The reload button also support a long press event
            Button(action: self.onReloadDefaultAction) {
                Text("reload_button")
            }
                .buttonStyle(sessionButtonStyle)
                .disabled(sessionButtonsDisabled)
                .modifier(LongPressModifier(
                    isDisabled: sessionButtonsDisabled,
                    completionHandler: self.onReloadPressed))

            // A button to make the current access token act expired
            Button(action: self.onExpireAccessToken) {
                Text("expire_access_token_button").multilineTextAlignment(.center)
            }
                .buttonStyle(sessionButtonStyle)
                .disabled(sessionButtonsDisabled)

            // A button to make the current refresh token act expired
            Button(action: self.onExpireRefreshToken) {
                Text("expire_refresh_token_button").multilineTextAlignment(.center)
            }
                .buttonStyle(sessionButtonStyle)
                .disabled(sessionButtonsDisabled)

            // A button to initiate a logout
            Button(action: self.onLogoutPressed) {
                Text("logout_button")
            }
                .buttonStyle(sessionButtonStyle)
                .disabled(sessionButtonsDisabled)
        }
        .onReceive(self.eventBus.navigatedTopic, perform: {data in
            self.handleNavigateEvent(event: data)
        })
        .onReceive(self.eventBus.viewModelFetchTopic, perform: {data in
            self.handleViewModelFetchEvent(event: data)
        })
    }

    /*
     * Update our state when the event is received
     */
    private func handleViewModelFetchEvent(event: ViewModelFetchEvent) {
        self.hasData = event.loaded
    }

    /*
     * Update our state when the main view changes
     */
    private func handleNavigateEvent(event: NavigatedEvent) {

        if event.isAuthenticatedView {
            self.homeTitle = NSLocalizedString("home_button", comment: "")
        } else {
            self.homeTitle = NSLocalizedString("login_button", comment: "")
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

    /*
     * Clear this view's state and then call the parent
     */
    private func onLogoutPressed() {
        self.hasData = false
        self.onLogout()
    }
}
