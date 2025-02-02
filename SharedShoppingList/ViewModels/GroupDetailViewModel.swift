import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupDetailView: View {
    let group: Group
    @State private var showCopyAlert: Bool = false
    @State private var memberDisplayNames: [String: String] = [:] // UIDとdisplayNameのマッピング

    var body: some View {
        Form {
            Section(header: Text("グループ情報")) {
                TextField("グループ名", text: .constant(group.name))
                
                // 招待コード表示とコピー機能
                HStack {
                    Text("招待コード: \(group.inviteCode)")
                    Spacer()
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .contentShape(Rectangle()) // タップ領域を広げる
                .onTapGesture {
                    UIPasteboard.general.string = group.inviteCode
                    showCopyAlert = true
                }
            }
            
            Section(header: Text("メンバー一覧")) {
                ForEach(group.members, id: \.self) { member in
                    Text(memberDisplayNames[member] ?? "読み込み中...")
                }
            }
        }
        .navigationTitle("グループ詳細")
        .onAppear {
            fetchDisplayNames()
        }
        .alert(isPresented: $showCopyAlert) {
            Alert(title: Text("コピー完了"), message: Text("招待コードがコピーされました。"), dismissButton: .default(Text("OK")))
        }
    }

    // FirestoreからユーザーのdisplayNameを取得
    func fetchDisplayNames() {
        let db = Firestore.firestore()
        
        for uid in group.members {
            db.collection("users").document(uid).getDocument { document, error in
                if let document = document, document.exists {
                    let displayName = document.data()?["displayName"] as? String ?? "未設定"
                    DispatchQueue.main.async {
                        memberDisplayNames[uid] = displayName
                    }
                } else {
                    DispatchQueue.main.async {
                        memberDisplayNames[uid] = "不明なユーザー"
                    }
                }
            }
        }
    }
}
