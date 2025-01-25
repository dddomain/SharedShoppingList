import Firebase
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationManager()
    private let tokenFetchURL = "https://your-server.com/get-access-token" // アクセストークン取得URL
    private let fcmSendURL = "https://fcm.googleapis.com/v1/projects/sharedshoppinglist-feecd/messages:send" // FCM送信URL

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
        db.collection("users").document(userID).setData(["fcmToken": token], merge: true) { error in
            if let error = error {
                print("トークン保存エラー: \(error.localizedDescription)")
            } else {
                print("トークンを保存しました: \(token)")
            }
        }
    }

    // プッシュ通知を送信
    func sendNotification(to token: String, title: String, body: String) {
        guard let url = URL(string: fcmSendURL) else { return }
        fetchAccessToken { [weak self] accessToken in
            guard let accessToken = accessToken else {
                print("アクセストークンが取得できません")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    print("通知送信失敗: ステータスコード \(httpResponse.statusCode)")
                } else {
                    print("通知送信成功")
                }
            }.resume()
        }
    }

    // アクセストークンをサーバーから取得
    func fetchAccessToken(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: tokenFetchURL) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("アクセストークン取得エラー: \(error.localizedDescription)")
                completion(nil)
            } else if let data = data, let token = String(data: data, encoding: .utf8) {
                print("アクセストークン取得成功")
                completion(token)
            } else {
                print("アクセストークンが不明な形式で返されました")
                completion(nil)
            }
        }.resume()
    }

    // フォアグラウンドでの通知処理
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("通知を受け取りました: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }

    // グループ全員への通知メソッド
    func sendGroupNotification(for group: Group, title: String, body: String) {
        let db = Firestore.firestore()
        db.collection("users").whereField("groupID", isEqualTo: group.id).getDocuments { snapshot, error in
            if let error = error {
                print("グループトークン取得エラー: \(error.localizedDescription)")
                return
            }

            let tokens = snapshot?.documents.compactMap { $0.data()["fcmToken"] as? String } ?? []

            for token in tokens {
                self.sendNotification(to: token, title: title, body: body)
            }
            print("グループ全員に通知を送信しました: \(tokens.count)件")
        }
    }
}   
