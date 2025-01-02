import FirebaseAuth
import FirebaseFirestore

struct UserInfoManager {
    // ユーザー情報を取得する関数
    static func fetchUserInfo(completion: @escaping (String, String, String, String) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion("", "未設定", "未設定", "未設定")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let userName = "\(data?["firstName"] as? String ?? "") \(data?["lastName"] as? String ?? "")"
                let displayName = data?["displayName"] as? String ?? "未設定"
                let email = data?["email"] as? String ?? "未設定"
                
                var birthdate = "未設定"
                if let timestamp = data?["birthdate"] as? Timestamp {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    birthdate = dateFormatter.string(from: timestamp.dateValue())
                }

                completion(userName, displayName, email, birthdate)
            } else {
                completion("", "未設定", "未設定", "未設定")
            }
        }
    }
}
