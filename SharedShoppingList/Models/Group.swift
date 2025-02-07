import SwiftUI
import FirebaseFirestore

struct Group: Identifiable {
    var id: String
    var name: String
    var inviteCode: String
    var members: [String]
    var memberDisplayNames: [String] = []  // メンバーのdisplayName
    var memberColors: [String: Color] = [:]  // メンバーの色

    /// メンバーの `displayName` を取得
    func fetchMemberDisplayNames(completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        var updatedDisplayNames: [String] = []

        for memberId in members {
            db.collection("users").document(memberId).getDocument { document, error in
                if let document = document, document.exists {
                    let displayName = document.data()?["displayName"] as? String ?? "不明"
                    DispatchQueue.main.async {
                        updatedDisplayNames.append(displayName)
                        if updatedDisplayNames.count == self.members.count {
                            completion(updatedDisplayNames)
                        }
                    }
                }
            }
        }
    }

    /// 🔥 メンバーの `colorTheme` を取得
    func fetchMemberColors(completion: @escaping ([String: Color]) -> Void) {
        let db = Firestore.firestore()
        var updatedColors: [String: Color] = [:]

        for memberId in members {
            db.collection("users").document(memberId).getDocument { document, error in
                if let document = document, document.exists {
                    let colorName = document.data()?["colorTheme"] as? String ?? "blue"
                    let color = ColorManager.getColor(from: colorName)

                    DispatchQueue.main.async {
                        updatedColors[memberId] = color
                        if updatedColors.count == self.members.count {
                            completion(updatedColors)
                        }
                    }
                }
            }
        }
    }
}
