import SwiftUI
import FirebaseFirestore

struct Group: Identifiable {
    var id: String
    var name: String
    var inviteCode: String
    var members: [String]
    var memberDisplayNames: [String] = []  // メンバーのdisplayNameを格納

    // メンバーの displayName を取得するメソッド
    func fetchMemberDisplayNames(completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        var updatedDisplayNames: [String] = []  // 一時的に名前を保持
        
        for memberId in members {
            db.collection("users").document(memberId).getDocument { document, error in
                if let document = document, document.exists {
                    let displayName = document.data()?["displayName"] as? String ?? "不明"
                    DispatchQueue.main.async {
                        updatedDisplayNames.append(displayName)
                        
                        // 全てのメンバーの名前が取得されたらクロージャで返す
                        if updatedDisplayNames.count == self.members.count {
                            completion(updatedDisplayNames)
                        }
                    }
                }
            }
        }
    }
}
