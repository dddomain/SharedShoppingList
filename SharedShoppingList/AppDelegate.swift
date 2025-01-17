import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Firebase初期化
        FirebaseApp.configure()
        
        // NotificationManager初期化
        NotificationManager.shared.configure()
        
        return true
    }
}
