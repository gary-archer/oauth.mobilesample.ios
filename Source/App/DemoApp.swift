import Foundation
import SwiftUI

/*
 * The application entry point
 */
@main
struct DemoAppApp: App {

    private let model: AppViewModel
    private let viewRouter: ViewRouter
    private let orientationHandler: OrientationHandler
    private let dataReloadHandler: DataReloadHandler

    /*
     * Create global models and environment objects during application startup
     */
    init() {
        self.model = AppViewModel()
        self.viewRouter = ViewRouter()
        self.orientationHandler = OrientationHandler()
        self.dataReloadHandler = DataReloadHandler()
    }

    /*
     * The app's main layout
     */
    var body: some Scene {

        WindowGroup {
            AppView(model: self.model, viewRouter: self.viewRouter)
                .environmentObject(self.orientationHandler)
                .environmentObject(self.dataReloadHandler)
                .onOpenURL(perform: { url in

                    // All deep link notifications are received here
                    // This includes claimed HTTPS scheme login / logout responses and deep links that start the app
                    self.viewRouter.handleDeepLink(url: url)
                })
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in

                    // Handle orientation changes in the app by updating the handler
                    // We also need to include the handler as an environment object in all views which need redrawing
                    self.orientationHandler.isLandscape = UIDevice.current.orientation.isLandscape
                }
        }
    }
}
