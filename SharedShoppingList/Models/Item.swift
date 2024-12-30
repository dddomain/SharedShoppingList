
import SwiftUI

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
}
