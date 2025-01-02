
import SwiftUI

struct ItemRowView: View {
    let item: Item
    let groupName: String
    let members: [String]  // メンバー情報を追加
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: item.purchased ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    onTap()
                }
            NavigationLink(destination: ItemDetailView(group: Group(id: item.groupId ?? "", name: groupName, inviteCode: "", members: members), item: item)) {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    Text(groupName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
