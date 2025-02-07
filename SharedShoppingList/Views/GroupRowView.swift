import SwiftUI

struct GroupRowView: View {
    let group: Group
    @State private var memberData: [String: (String, Color)] = [:]  // 🔥 UIDごとの表示名とカラー

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                    Text(group.members.count == 1 ? "自分のみ" : "\(group.members.count)人")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(group.members, id: \.self) { userId in
                            if let (displayName, color) = memberData[userId] {
                                Text(displayName)
                                    .font(.caption)
                                    .foregroundColor(color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(color.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            UserInfoManager.shared.fetchMemberData(userIds: group.members) { data in
                self.memberData = data
            }
        }
    }
}
