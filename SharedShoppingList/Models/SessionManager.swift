import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UIKit

class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var user: User? = nil
    @Published var showProfile: Bool = false

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.user = user
                self?.isLoggedIn = true
                print("✅ ユーザーがログインしました: \(user.uid)")
                self?.updateFCMToken() // 🔥 ログイン時に最新の FCM トークンを Firestore に保存
            } else {
                self?.isLoggedIn = false
                print("🚪 ユーザーがログアウトしました")
            }
        }
    }

    func updateFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("⚠️ FCM トークン取得エラー: \(error.localizedDescription)")
                return
            }
            
            guard let token = token, let userId = self.user?.uid else {
                print("⚠️ ユーザー情報が取得できないため、FCM トークンを保存しません")
                return
            }

            let db = Firestore.firestore()
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let deviceRef = db.collection("devices").document(deviceId)

            // 🔥 すでにトークンが登録されているか確認してから追加
            deviceRef.getDocument { document, error in
                if let document = document, document.exists {
                    var existingTokens = document.data()?["fcmTokens"] as? [String] ?? []
                    
                    if !existingTokens.contains(token) {
                        existingTokens.append(token)
                        deviceRef.setData([
                            "fcmTokens": existingTokens,
                            "userId": userId,
                            "lastUpdated": Timestamp(date: Date())
                        ], merge: true)
                        print("🔥 Firestore に新しい FCM トークンを保存: \(token)")
                    } else {
                        print("✅ 既存の FCM トークンのため保存不要: \(token)")
                    }
                } else {
                    deviceRef.setData([
                        "fcmTokens": [token],
                        "userId": userId,
                        "lastUpdated": Timestamp(date: Date())
                    ])
                    print("🔥 Firestore に FCM トークンを初回保存: \(token)")
                }
            }
        }
    }
}
