import UIKit

/*
 * Deals with process events and application lifecycle
 */
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /*
     * Override point for customization after application launch
     */
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        return true
    }

    /*
     * Use this method to select a configuration to create the new scene with
     */
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /*
     * Called when the user discards a scene session.
     * This will be called shortly after application:didFinishLaunchingWithOptions
    *    if any sessions were discarded while the application was not running
     * Use this method to release any resources that were specific to the discarded scenes, as they will not return
     */
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
