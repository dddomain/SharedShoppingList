import UIKit
import Firebase
import FirebaseMessaging
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 🔥 Firebase 初期化
        FirebaseApp.configure()

        // 🔥 通知の設定
        NotificationManager.shared.configure()
        
        // 🔥 Firebase Messaging のデリゲート設定
        Messaging.messaging().delegate = self

        return true
    }

    // 🔥 APNs トークンを FCM に登録
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("✅ APNs トークンを取得: \(deviceToken)")
    }

    // 🔥 FCM トークンが変更されたときに Firestore に保存
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("⚠️ FCM トークンが取得できませんでした")
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            print("⚠️ ログインユーザーが取得できません。FCM トークンを保存しません")
            return
        }

        print("🔥 Firestore に保存する FCM トークン: \(token)")
        
        let db = Firestore.firestore()
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceRef = db.collection("devices").document(deviceId)

        // 🔥 既存のトークンをチェックしてから保存
        deviceRef.getDocument { document, error in
            if let document = document, document.exists {
                var existingTokens = document.data()?["fcmTokens"] as? [String] ?? []
                
                if !existingTokens.contains(token) {
                    existingTokens.append(token)
                    deviceRef.setData([
                        "fcmTokens": existingTokens,
                        "userId": user.uid,
                        "lastUpdated": Timestamp(date: Date())
                    ], merge: true)
                    print("✅ Firestore に新しい FCM トークンを保存しました: \(token)")
                } else {
                    print("✅ 既存の FCM トークンのため保存不要: \(token)")
                }
            } else {
                deviceRef.setData([
                    "fcmTokens": [token],
                    "userId": user.uid,
                    "lastUpdated": Timestamp(date: Date())
                ])
                print("✅ Firestore に FCM トークンを初回保存しました: \(token)")
            }
        }
    }
}
