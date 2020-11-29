import SwiftUI

/*
 * Represents the title row
 */
struct TitleView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @ObservedObject private var userInfoViewModel: UserInfoViewModel
    @State private var title = "OAuth 2.x Demo App"
    private var shouldLoadUserInfo: Bool

    /*
     * Construct from the user info view model, which is only created once
     */
    init (userInfoViewModel: UserInfoViewModel, shouldLoadUserInfo: Bool) {
        self.userInfoViewModel = userInfoViewModel
        self.shouldLoadUserInfo = shouldLoadUserInfo
    }

    /*
     * Render the UI elements
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        let titleWidth = shouldLoadUserInfo ? deviceWidth * 0.55 : deviceWidth
        let userInfoWidth = deviceWidth * 0.45

        return HStack {

            // Show the title aligned left
            Text(self.title)
                .fontWeight(.bold)
                .padding(20)
                .font(.system(size: 16))
                .frame(width: titleWidth, alignment: .leading)

            // Show the user name to the right
            if self.shouldLoadUserInfo {
                UserInfoView(
                    model: self.userInfoViewModel,
                    shouldLoad: self.shouldLoadUserInfo)
                        .padding(20)
                        .frame(width: userInfoWidth, alignment: .trailing)
            }
        }
    }
}
