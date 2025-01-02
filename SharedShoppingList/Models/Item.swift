import SwiftUI
import FirebaseFirestore

struct Item: Identifiable {
    var id: String
    var name: String
    var purchased: Bool
    var order: Int
    var location: String
    var url: String
    var quantity: Int
    var deadline: String
    var memo: String
    var registeredAt: String
    var registrant: String
    var buyer: String?
    var purchasedAt: String?
    var groupId: String? = nil
    
    // グループIDを取得するメソッド（mutatingは使用しない）
    // なぜこの方法が必要か？
    // swiftの構造体（struct）は値型であり、mutating関数以外ではselfを変更できません。
    // 非同期処理が発生するクロージャ内ではselfを直接変更することができず、このエラーが発生します。
    func fetchGroupId(completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("groups").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                for document in documents {
                    let groupRef = db.collection("groups").document(document.documentID).collection("items").document(self.id)
                    
                    groupRef.getDocument { itemDoc, error in
                        if itemDoc?.exists == true {
                            // グループIDをクロージャ経由で返す
                            completion(document.documentID)
                            return
                        }
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
}
