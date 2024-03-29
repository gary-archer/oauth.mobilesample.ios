import Foundation
import SwiftUI

/*
 * The Swift UI application entry point
 */
@main
struct SampleApp: App {

    // The main view model
    private let model: AppViewModel

    // Environment objects
    private let eventBus: EventBus
    private let orientationHandler: OrientationHandler
    private let viewRouter: ViewRouter

    /*
     * Create environment objects and global models during application startup
     */
    init() {

        // Create environment objects
        self.eventBus = EventBus()
        self.orientationHandler = OrientationHandler()

        // Create the main view model
        self.model = AppViewModel(eventBus: self.eventBus)

        // Create a router object for managing navigation
        self.viewRouter = ViewRouter(eventBus: self.eventBus)
    }

    /*
     * The app's main layout
     */
    var body: some Scene {

        WindowGroup {
            AppView(model: self.model, viewRouter: self.viewRouter)
                .environmentObject(self.eventBus)
                .environmentObject(self.orientationHandler)
                .onOpenURL(perform: { url in

                    if !self.model.isLoaded {

                        // If we receive a deep link before the app is loaded it is a deep link startup URL
                        self.model.deepLinkStartupUrl = url

                    } else {

                        // Handle login responses when required
                        if !self.model.resumeOAuthResponse(url: url) {

                            // Handle other deep links in the view router
                            self.viewRouter.handleDeepLink(url: url)
                        }
                    }
                })
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in

                    // Handle orientation changes in the app by updating the handler
                    // We also need to include the handler as an environment object in all views which need redrawing
                    self.orientationHandler.isLandscape = UIDevice.current.orientation.isLandscape
                }
        }
    }
}
