import UIKit
import SwiftUI

/*
 * Application startup and lifecycle events
 */
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // Published objects for this app
    private var viewRouter = ViewRouter()
    private var orientationHandler = OrientationHandler()
    private var dataReloadHandler = DataReloadHandler()

    /*
     * Use this method to optionally configure and attach the UIWindow to the provided UIWindowScene
     * If using a storyboard, the window property will automatically be initialized and attached to the scene
     * This delegate does not imply the connecting scene or session are new
     * See application:configurationForConnectingSceneSession
     */
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions) {

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {

            // Create the main view
            let window = UIWindow(windowScene: windowScene)
            let appView = AppView(viewRouter: self.viewRouter)

            // Finish window creation and supply environment objects
            self.orientationHandler.isLandscape = windowScene.interfaceOrientation.isLandscape
            window.rootViewController = UIHostingController(
                rootView: appView
                    .environmentObject(self.orientationHandler)
                    .environmentObject(self.dataReloadHandler))

            self.window = window
            window.makeKeyAndVisible()

            // Deep link notifications that start the app are processed here
            let activity = connectionOptions.userActivities.first
            if activity != nil {
                self.viewRouter.handleStartupDeepLink(url: activity!.webpageURL!)
            }
        }
    }

    /*
     * Handle repainting views when there is a change in device orientation
     */
    func windowScene(
        _ windowScene: UIWindowScene,
        didUpdate previousCoordinateSpace: UICoordinateSpace,
        interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
        traitCollection previousTraitCollection: UITraitCollection) {

        // Set the updated orientation
        orientationHandler.isLandscape = windowScene.interfaceOrientation.isLandscape
    }

    /*
     * Deep link notifications are received here after the app has started
     * This includes claimed HTTPS scheme login / logout responses
     */
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {

        if userActivity.webpageURL != nil {
            self.viewRouter.handleDeepLink(url: userActivity.webpageURL!)
        }
    }

    /*
     * Called as the scene is being released by the system
     * This occurs shortly after the scene enters the background, or when its session is discarded
     * Release any resources associated with this scene that can be re-created the next time the scene connects
     * The scene may re-connect later, as its session was not neccessarily discarded
     * See `application:didDiscardSceneSessions` instead
     */
    func sceneDidDisconnect(_ scene: UIScene) {
    }

    /*
     * Called when the scene has moved from an inactive state to an active state
     * Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive
     */
    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    /*
     * Called when the scene will move from an active state to an inactive state
     * This may occur due to temporary interruptions (ex. an incoming phone call)
     */
    func sceneWillResignActive(_ scene: UIScene) {
    }

    /*
     * Called as the scene transitions from the background to the foreground
     * Use this method to undo the changes made on entering the background
     */
    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    /*
     * Called as the scene transitions from the foreground to the background
     * Use this method to save data, release shared resources, and store enough scene-specific state information
     * to restore the scene back to its current state.
     */
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
