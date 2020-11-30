import Foundation
import SwiftUI

/*
 * The application entry point
 */
@main
struct DemoAppApp: App {

    private let viewRouter = ViewRouter()
    private let orientationHandler = OrientationHandler()
    private let dataReloadHandler = DataReloadHandler()

    /*
     * The app's main layout
     */
    var body: some Scene {

        WindowGroup {
            AppView(model: AppViewModel(), viewRouter: self.viewRouter)
                .environmentObject(self.orientationHandler)
                .environmentObject(self.dataReloadHandler)
                .onOpenURL(perform: self.onOpenUrl)
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in

                    // We must also include the orientiation handler environment object in all views that need redrawing
                    self.orientationHandler.isLandscape = UIDevice.current.orientation.isLandscape
                }
        }
    }

    /*
     * All deep link notifications are received here
     * This includes claimed HTTPS scheme login / logout responses and deep links that start the app
     */
    private func onOpenUrl(url: URL) {
        self.viewRouter.handleDeepLink(url: url)
    }
}
