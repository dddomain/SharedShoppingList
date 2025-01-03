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
    
    init(
        id: String,
        name: String,
        purchased: Bool,
        order: Int,
        location: String,
        url: String,
        quantity: Int,
        deadline: String,
        memo: String,
        registeredAt: String,
        registrant: String,
        buyer: String? = nil,
        purchasedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.purchased = purchased
        self.order = order
        self.location = location
        self.url = url
        self.quantity = quantity
        self.deadline = deadline
        self.memo = memo
        self.registeredAt = registeredAt
        self.registrant = registrant
        self.buyer = buyer
        self.purchasedAt = purchasedAt
        
        // グループIDを取得してプロパティに格納
        var item = self
        fetchGroupId { fetchedGroupId in
            item.groupId = fetchedGroupId
        }
    }
    
    // 非同期でグループIDを取得するメソッド
    private func fetchGroupId(completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("groups").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                for document in documents {
                    let groupRef = db.collection("groups").document(document.documentID).collection("items").document(self.id)
                    
                    groupRef.getDocument { itemDoc, error in
                        if itemDoc?.exists == true {
                            completion(document.documentID)
                            return
                        }
                    }
                }
            }
            completion(nil)
        }
    }
}
