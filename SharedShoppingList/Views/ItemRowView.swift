import SwiftUI

struct ItemRowView: View {
    let item: Item
    let groupName: String
    let members: [String]
    let context: String  // "home" or "list" を想定
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: item.purchased ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    onTap()
                }
            NavigationLink(destination: destinationView()) {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    
                    if context == "home" {
                        Text(groupName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if context == "list" {
                        HStack {
                            Text("個数: \(item.quantity)")
                                .foregroundColor(.primary)
                            Text(item.deadline.isEmpty ? "期限なし" : "期限: \(item.deadline)")
                                .font(.caption)
                                .foregroundColor(item.deadline.isEmpty ? .gray : .red)
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func destinationView() -> some View {
        if let groupId = item.groupId, !groupId.isEmpty {
            ItemDetailView(group: Group(id: groupId, name: groupName, inviteCode: "", members: members), item: item)
        } else {
            Text("グループ情報が存在しません").foregroundColor(.red)
        }
    }
}
