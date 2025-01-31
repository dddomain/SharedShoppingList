import Firebase
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationManager()
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
                print("[DEBUG] 通知許可エラー: \(error.localizedDescription)")
            } else {
                print("[DEBUG] 通知許可が完了しました: granted = \(granted)")
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }

    // デバイストークンを取得したときの処理
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("[DEBUG] FCMトークンがnilです")
            return
        }
        print("[DEBUG] FCMトークンを取得しました: \(fcmToken)")
        saveTokenToServer(fcmToken)
    }

    // トークンをサーバーに保存
    func saveTokenToServer(_ token: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("[DEBUG] ユーザーIDが取得できません")
            return
        }
        print("[DEBUG] ユーザーID: \(userID)")

        let db = Firestore.firestore()
        db.collection("users").document(userID).setData(["fcmToken": token], merge: true) { error in
            if let error = error {
                print("[DEBUG] トークン保存エラー: \(error.localizedDescription)")
            } else {
                print("[DEBUG] トークンを保存しました: \(token)")
            }
        }
    }

    // プッシュ通知を送信
    func sendNotification(to token: String, title: String, body: String) {
        guard let url = URL(string: "https://us-central1-sharedshoppinglist-feecd.cloudfunctions.net/sendPushNotification") else {
            print("[DEBUG] FCM送信URLが無効です")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "token": token,
            "title": title,
            "body": body
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            print("[DEBUG] ペイロードを作成しました: \(payload)")
        } catch {
            print("[DEBUG] ペイロード作成エラー: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DEBUG] 通知送信エラー: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("[DEBUG] 通知送信ステータスコード: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] 通知送信レスポンス: \(responseString)")
                }
            }
        }.resume()
    }


    // フォアグラウンドでの通知処理
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("[DEBUG] 通知を受け取りました: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }

    // グループ全員への通知メソッド
    func sendGroupNotification(for group: Group, title: String, body: String) {
        let db = Firestore.firestore()

        // グループドキュメントを取得してメンバー情報を取得
        db.collection("groups").document(group.id).getDocument { document, error in
            if let error = error {
                print("[DEBUG] グループトークン取得エラー: \(error.localizedDescription)")
                return
            }

            guard let document = document, let data = document.data(),
                  let members = data["members"] as? [String] else {
                print("[DEBUG] メンバー情報が見つかりません")
                return
            }

            print("[DEBUG] メンバー情報を取得しました: \(members)")

            // メンバーのUIDをもとに `users` コレクションを参照してトークンを取得
            db.collection("users").whereField(FieldPath.documentID(), in: members).getDocuments { snapshot, error in
                if let error = error {
                    print("[DEBUG] ユーザートークン取得エラー: \(error.localizedDescription)")
                    return
                }

                // FCMトークンを収集
                let tokens = snapshot?.documents.compactMap { $0.data()["fcmToken"] as? String } ?? []
                print("[DEBUG] 取得したトークン: \(tokens)")
                for token in tokens {
                    self.sendNotification(to: token, title: title, body: body)
                }
                print("[DEBUG] グループ全員に通知を送信しました: \(tokens.count)件")
            }
        }
    }
}
