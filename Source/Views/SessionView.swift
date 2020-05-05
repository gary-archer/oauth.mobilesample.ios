import SwiftUI

/*
* A visual indication of how requests sent to the API are grouped
*/
struct SessionView: View {

    // Properties
    private let apiClient: ApiClient
    private let isVisible: Bool

    /*
     * Initialise from input
     */
    init (apiClient: ApiClient, isVisible: Bool) {
        self.apiClient = apiClient
        self.isVisible = isVisible
    }

    /*
     * Render the view
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {
            if !self.isVisible {

                Text("")
                    .hidden()
                    .frame(height: 0)

            } else {

                Text("API Session Id: \(self.apiClient.sessionId)")
                    .foregroundColor(Color.gray)
                    .fontWeight(.light)
                    .font(.system(size: 12))
                    .frame(maxWidth: deviceWidth, alignment: .trailing)
                    .padding(.trailing, 25)
            }
        }
    }
}
