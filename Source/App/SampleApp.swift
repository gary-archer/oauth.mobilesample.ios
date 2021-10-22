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
    private var apiClient: ApiClient

    // The main view model
    private let model: AppViewModel

    // Environment objects
    private let eventPublisher: EventPublisher
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
        self.apiClient = try! ApiClient(
            appConfiguration: self.configuration.app,
            authenticator: self.authenticator)

        // First create environment objects
        self.eventPublisher = EventPublisher()
        self.orientationHandler = OrientationHandler()

        // Create global view models
        self.model = AppViewModel(
            configuration: self.configuration,
            authenticator: self.authenticator,
            apiClient: self.apiClient,
            eventPublisher: self.eventPublisher)

        // Create a router object
        self.viewRouter = ViewRouter(
            handleOAuthDeepLink: model.handleOAuthDeepLink,
            onDeepLinkCompleted: model.onDeepLinkCompleted)
    }

    /*
     * The app's main layout
     */
    var body: some Scene {

        WindowGroup {
            AppView(model: self.model, viewRouter: self.viewRouter)
                .environmentObject(self.orientationHandler)
                .environmentObject(self.eventPublisher)
                .onOpenURL(perform: { url in

                    // All deep link notifications are received here
                    // This includes claimed HTTPS scheme login / logout responses and deep links that start the app
                    // Startup deep links run the default view first and do not behave totally correctly when logged out
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
