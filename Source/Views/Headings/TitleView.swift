import SwiftUI

/*
 * Represents the title row
 */
struct TitleView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @ObservedObject private var userInfoViewModel: UserInfoViewModel
    private let title = "OAuth Demo App"
    private let viewRouter: ViewRouter

    /*
     * Construct from the user info view model, which is only created once
     */
    init (userInfoViewModel: UserInfoViewModel, viewRouter: ViewRouter) {
        self.userInfoViewModel = userInfoViewModel
        self.viewRouter = viewRouter
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
            Text(self.title)
                .fontWeight(.bold)
                .padding(20)
                .font(.system(size: 16))
                .frame(width: titleWidth, alignment: .leading)

            // Show the user name to the right
            UserInfoView(model: self.userInfoViewModel, viewRouter: self.viewRouter)
                .padding(20)
                .frame(width: userInfoWidth, alignment: .trailing)
        }
    }
}
