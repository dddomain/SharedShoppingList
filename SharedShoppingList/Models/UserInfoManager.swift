import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class UserInfoManager: ObservableObject {
    @Published var colorTheme: Color = .blue  // デフォルトカラー
    @Published var userName: String = ""
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var birthdate: String = "未設定"
    
    @AppStorage("userColor") var storedColor: String = "blue"

    static let shared = UserInfoManager()

    private init() {
        loadUserInfo() // ユーザー情報とカラーを一括ロード
    }

    /// Firestore からユーザー情報を取得
    func loadUserInfo() {
        guard let user = Auth.auth().currentUser else {
            print("[UserInfoManager] ユーザー未ログインのため情報を取得できません")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let error = error {
                print("[UserInfoManager] ユーザー情報取得エラー: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                DispatchQueue.main.async {
                    self.userName = "\(data?["firstName"] as? String ?? "") \(data?["lastName"] as? String ?? "")"
                    self.displayName = data?["displayName"] as? String ?? "未設定"
                    self.email = data?["email"] as? String ?? "未設定"

                    if let timestamp = data?["birthdate"] as? Timestamp {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        self.birthdate = formatter.string(from: timestamp.dateValue())
                    }

                    let colorName = data?["colorTheme"] as? String ?? "blue"
                    self.colorTheme = ColorManager.getColor(from: colorName)
                    self.storedColor = colorName
                    print("[UserInfoManager] ユーザー情報 & カラー適用: \(colorName)")
                }
            } else {
                print("[UserInfoManager] Firestore にユーザー情報がありません")
            }
        }
    }

    /// Firestore にカラー設定を保存
    func saveUserColor(_ color: String) {
        guard let user = Auth.auth().currentUser else {
            print("[UserInfoManager] ユーザー未ログインのためカラーを保存できません")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid)
            .setData(["colorTheme": color], merge: true) { error in
                if let error = error {
                    print("[UserInfoManager] カラー設定の保存エラー: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.colorTheme = ColorManager.getColor(from: color)
                        self.storedColor = color  // 🔥 ローカルストレージにも反映
                        print("[UserInfoManager] ユーザーのカラーを保存: \(color)")
                    }
                }
            }
    }
}
