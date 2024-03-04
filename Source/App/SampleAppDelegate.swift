import SwiftUI

/*
 * Boiler plate to create an app delegate and connect it to a scene delegate
 */
class SampleAppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        let sceneConfig: UISceneConfiguration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role)

        sceneConfig.delegateClass = SampleSceneDelegate.self
        return sceneConfig
    }
}
