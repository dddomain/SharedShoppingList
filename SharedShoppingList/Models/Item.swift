
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
    var deadline: Date?
    var memo: String
    var registeredAt: Date
    var registrant: String
    var buyer: String?
    var purchasedAt: Date?  // 購入日もDate型に変更
    var groupId: String
    
    init(
        id: String,
        name: String,
        purchased: Bool,
        order: Int,
        location: String,
        url: String,
        quantity: Int,
        deadline: Timestamp?,  // Optional
        memo: String,
        registeredAt: Date,
        registrant: String,
        buyer: String? = nil,
        purchasedAt: Timestamp? = nil,  // Timestamp型をOptionalで受け取る
        groupId: String
    ) {
        self.id = id
        self.name = name
        self.purchased = purchased
        self.order = order
        self.location = location
        self.url = url
        self.quantity = quantity
        self.deadline = deadline?.dateValue()  // Optionalであればnilが入る
        self.memo = memo
        self.registeredAt = registeredAt
        self.registrant = registrant
        self.buyer = buyer
        self.purchasedAt = purchasedAt?.dateValue()  // Optionalの購入日をDate型に変換
        self.groupId = groupId
    }
}
