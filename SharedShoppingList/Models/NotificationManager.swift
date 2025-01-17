import Firebase
import FirebaseAuth
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    // プッシュ通知の初期化
    func configure() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("通知許可エラー: \(error.localizedDescription)")
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // デバイストークンを取得したときの処理
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCMトークン: \(fcmToken)")
        saveTokenToServer(fcmToken)
    }
    
    // トークンをサーバーに保存
    func saveTokenToServer(_ token: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("ユーザーIDが取得できません")
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData(["fcmToken": token]) { error in
            if let error = error {
                print("トークン保存エラー: \(error.localizedDescription)")
            } else {
                print("トークンを保存しました: \(token)")
            }
        }
    }
    
    // プッシュ通知を送信
    func sendNotification(to token: String, title: String, body: String) {
        let url = URL(string: "https://fcm.googleapis.com/v1/projects/your-project-id/messages:send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // アクセストークンを取得（サーバーからのレスポンスを利用）
        fetchAccessToken { accessToken in
            guard let accessToken = accessToken else {
                print("アクセストークンが取得できません")
                return
            }
            
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let payload: [String: Any] = [
                "message": [
                    "token": token,
                    "notification": [
                        "title": title,
                        "body": body
                    ]
                ]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("通知送信エラー: \(error.localizedDescription)")
                } else {
                    print("通知送信成功")
                }
            }.resume()
        }
    }

    // アクセストークンをサーバーから取得
    func fetchAccessToken(completion: @escaping (String?) -> Void) {
        let tokenURL = URL(string: "https://your-server.com/get-access-token")! // サーバーのAPIエンドポイント
        URLSession.shared.dataTask(with: tokenURL) { data, _, error in
            if let error = error {
                print("アクセストークン取得エラー: \(error.localizedDescription)")
                completion(nil)
            } else if let data = data {
                let token = String(data: data, encoding: .utf8)
                completion(token)
            }
        }.resume()
    }

    
    // フォアグラウンドでの通知処理
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
