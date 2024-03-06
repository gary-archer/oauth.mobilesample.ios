import SwiftUI

/*
 * Boiler plate to create a scene delegate that stores a startup deep link
 */
class SampleSceneDelegate: NSObject, UIWindowSceneDelegate {

    var window: UIWindow?
    static var startupDeepLinkUrl: String?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions) {

        if let url = connectionOptions.userActivities.first?.webpageURL {
            SampleSceneDelegate.startupDeepLinkUrl = url.absoluteString
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
