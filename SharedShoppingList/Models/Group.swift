
import SwiftUI

struct Group: Identifiable {
    var id: String
    var name: String
    var inviteCode: String
    var members: [String] = []
}
