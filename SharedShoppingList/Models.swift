
import SwiftUI

struct Group: Identifiable {
    var id: String
    var name: String
}

struct Item: Identifiable {
    var id: String
    var name: String
    var purchased: Bool
    var order: Int
}
