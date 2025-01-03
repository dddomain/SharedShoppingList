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
    var groupId: String?
    
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
        purchasedAt: String? = nil,
        groupId: String
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
        self.groupId = groupId
    }
}
