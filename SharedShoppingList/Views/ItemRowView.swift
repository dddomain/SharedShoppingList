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
                    HStack {
                        Text("個数: \(item.quantity)")
                            .foregroundColor(.primary)
                        Text("期限: \(item.deadline != nil ? formatDate(item.deadline!) : "なし")")
                            .font(.subheadline)
                            .foregroundColor(item.deadline == nil ? .gray : .red)
                    }
                    if context == "home" {
                        Text(groupName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if context == "list" {
                        // こちらのみで表示する情報はなし。
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func destinationView() -> some View {
        if !item.groupId.isEmpty {
            ItemDetailView(group: Group(id: item.groupId, name: groupName, inviteCode: "", members: members), item: item)
        } else {
            Text("グループ情報が存在しません").foregroundColor(.red)
        }
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未設定" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

}
