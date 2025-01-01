import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupDetailView: View {
    let group: Group

    var body: some View {
        Form {
            Section(header: Text("グループ情報")) {
                TextField("グループ名", text: .constant(group.name))
                Text("招待コード: \(group.inviteCode)")
            }
            
            Section(header: Text("メンバー一覧")) {
                ForEach(group.members, id: \.self) { member in
                    Text(member)
                }
            }
        }
        .navigationTitle("グループ詳細")
    }
}
