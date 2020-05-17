import SwiftUI

/*
 * Represents the title row
 */
struct TitleView: View {

    // External objects
    @EnvironmentObject var orientationHandler: OrientationHandler

    // Properties supplied as input
    private let apiClient: ApiClient?
    private let viewManager: ViewManager?
    private var shouldLoadUserInfo = false

    // This view's state
    @State private var title = "OAuth 2.0 Demo App"

    /*
     * Called once 
     */
    init (apiClient: ApiClient?, viewManager: ViewManager?, shouldLoadUserInfo: Bool) {
        self.apiClient = apiClient
        self.viewManager = viewManager
        self.shouldLoadUserInfo = shouldLoadUserInfo
    }

    /*
     * Render the view
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        let isInitialised = self.apiClient != nil

        let titleWidth = isInitialised ? deviceWidth * 0.55 : deviceWidth
        let userInfoWidth = deviceWidth * 0.45

        return HStack {

            // Show the title aligned left
            Text(self.title)
                .fontWeight(.bold)
                .padding(20)
                .font(.system(size: 16))
                .frame(width: titleWidth, alignment: .leading)

            // If we have initialised then also show user info
            if isInitialised {

                UserInfoView(
                    apiClient: self.apiClient!,
                    viewManager: self.viewManager!,
                    shouldLoad: self.shouldLoadUserInfo)
                        .padding(20)
                        .frame(width: userInfoWidth, alignment: .trailing)
            }
        }
    }
}
