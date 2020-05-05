import SwiftUI

/*
 * Represents the title row
 */
struct TitleView: View {

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

        HStack {

            // Show the title aligned left
            Text(self.title)
                .fontWeight(.bold)
                .padding(20)
                .font(.system(size: 16))
                .frame(width: UIScreen.main.bounds.size.width * 0.55, alignment: .leading)

            // If we have initialised then also show user info
            if self.apiClient != nil && self.viewManager != nil {

                UserInfoView(
                    apiClient: self.apiClient!,
                    viewManager: self.viewManager!,
                    shouldLoad: self.shouldLoadUserInfo)
                        .padding(20)
                        .frame(width: UIScreen.main.bounds.size.width  * 0.45, alignment: .trailing)
            }
        }
    }
}
