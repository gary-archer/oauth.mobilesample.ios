import Foundation
import SwiftUI

/*
 * The application entry point
 */
@main
struct DemoAppApp: App {

    // Application environment objects
    private let viewRouter = ViewRouter()
    private let orientationHandler = OrientationHandler()
    private let dataReloadHandler = DataReloadHandler()

    /*
     * The application layout 
     */
    var body: some Scene {
        WindowGroup {
            AppView(model: AppViewModel(), viewRouter: self.viewRouter)
                .environmentObject(self.orientationHandler)
                .environmentObject(self.dataReloadHandler)
                .onOpenURL(perform: self.onOpenUrl)
        }
    }

    /*
     * Deep link notifications are received here after the app has started
     * This includes claimed HTTPS scheme login / logout responses
     */
    private func onOpenUrl(url: URL) {
        self.viewRouter.handleDeepLink(url: url)
    }

    /*
    func windowScene(
        _ windowScene: UIWindowScene,
        didUpdate previousCoordinateSpace: UICoordinateSpace,
        interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
        traitCollection previousTraitCollection: UITraitCollection) {

        // Set the updated orientation
        self.orientationHandler.isLandscape = windowScene.interfaceOrientation.isLandscape
    }*/
}
