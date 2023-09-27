import SwiftUI

/*
 * Represents the title row
 */
struct TitleView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @ObservedObject private var userInfoViewModel: UserInfoViewModel

    /*
     * Construct from the user info view model, which is only created once
     */
    init (userInfoViewModel: UserInfoViewModel) {
        self.userInfoViewModel = userInfoViewModel
    }

    /*
     * Render the UI elements
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        let titleWidth = deviceWidth * 0.55
        let userInfoWidth = deviceWidth * 0.45

        return HStack {

            // Show the title aligned left
            Text("app_name")
                .fontWeight(.bold)
                .font(.system(size: 16))
                .padding(20)
                .frame(width: titleWidth, alignment: .leading)

            // Show the user name to the right
            UserInfoView(model: self.userInfoViewModel)
                .padding(20)
                .frame(width: userInfoWidth, alignment: .trailing)
        }
    }
}
