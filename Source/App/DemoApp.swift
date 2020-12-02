import Foundation
import SwiftUI

/*
 * The application entry point
 */
@main
struct DemoAppApp: App {

    private let dataReloadHandler: DataReloadHandler
    private let orientationHandler: OrientationHandler
    private let model: AppViewModel
    private let viewRouter: ViewRouter
    private let viewManager: ViewManager

    /*
     * Create environment objects and global models during application startup
     */
    init() {

        // First create environment objects
        self.dataReloadHandler = DataReloadHandler()
        self.orientationHandler = OrientationHandler()

        // Create global view models
        self.model = AppViewModel(dataReloadHandler: dataReloadHandler)

        // Create global view helpers
        self.viewRouter = ViewRouter(
            handleOAuthDeepLink: model.handleOAuthDeepLink,
            onDeepLinkCompleted: model.onDeepLinkCompleted)
        self.viewManager = ViewManager()
    }

    /*
     * The app's main layout
     */
    var body: some Scene {

        WindowGroup {
            AppView(model: self.model, viewRouter: self.viewRouter, viewManager: self.viewManager)
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
