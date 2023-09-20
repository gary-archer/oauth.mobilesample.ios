import Foundation
import SwiftUI

/*
 * The Swift UI application entry point
 */
@main
struct SampleApp: App {

    // Global objects created on startup
    private var configuration: Configuration
    private var authenticator: AuthenticatorImpl
    private var fetchClient: FetchClient

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

        // Load the configuration from the embedded resource
        // swiftlint:disable:next force_try
        self.configuration = try! ConfigurationLoader.load()

        // Create the global authenticator
        self.authenticator = AuthenticatorImpl(configuration: self.configuration.oauth)

        // Create the API Client from configuration
        // swiftlint:disable:next force_try
        self.fetchClient = try! FetchClient(configuration: self.configuration, authenticator: self.authenticator)

        // Create environment objects
        self.eventBus = EventBus()
        self.orientationHandler = OrientationHandler()

        // Create global view models
        self.model = AppViewModel(
            configuration: self.configuration,
            authenticator: self.authenticator,
            fetchClient: self.fetchClient,
            eventBus: self.eventBus)

        // Create a router object for managing navigation
        self.viewRouter = ViewRouter(eventBus: self.eventBus)
    }

    /*
     * The app's main layout
     */
    var body: some Scene {

        WindowGroup {
            AppView(model: self.model, viewRouter: self.viewRouter)
                .environmentObject(self.orientationHandler)
                .environmentObject(self.eventBus)
                .onOpenURL(perform: { url in

                    // All deep link notifications are received here
                    if self.authenticator.isOAuthResponse(responseUrl: url) {

                        // Handle claimed HTTPS scheme OAuth responses in the model
                        self.model.resumeOAuthResponse(url: url)

                    } else {

                        // Handle other deep links in the view router, including those that start the app
                        self.viewRouter.handleDeepLink(url: url)
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
