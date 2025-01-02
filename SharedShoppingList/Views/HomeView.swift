import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var items: [Item] = []
    @State private var groups: [String: Group] = [:]
    @State private var currentUserID: String? = Auth.auth().currentUser?.uid

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    Text(groups[item.groupId ?? ""]?.name ?? "不明なグループ")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("買いに行きましょう")
        .onAppear {
            Task {
                await fetchUserGroupsAndItems()
            }
        }
    }

    // Firestoreからユーザーが所属するグループとアイテムを同時に取得
    private func fetchUserGroupsAndItems() async {
        guard let userID = currentUserID else { return }
        let db = Firestore.firestore()

        do {
            // ユーザーがメンバーのグループを取得
            let groupSnapshot = try await db.collection("groups")
                .whereField("members", arrayContains: userID)
                .getDocuments()
            
            let fetchedGroups = groupSnapshot.documents.map { doc -> Group in
                let data = doc.data()
                return Group(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    inviteCode: data["inviteCode"] as? String ?? ""
                )
            }
            
            // グループ情報を辞書で管理
            DispatchQueue.main.async {
                self.groups = Dictionary(uniqueKeysWithValues: fetchedGroups.map { ($0.id, $0) })
            }
            
            // 未購入アイテムを取得
            var fetchedItems: [Item] = []
            for group in fetchedGroups {
                let itemSnapshot = try await db.collection("groups")
                    .document(group.id)
                    .collection("items")
                    .whereField("purchased", isEqualTo: false)
                    .getDocuments()
                
                let items = itemSnapshot.documents.map { doc -> Item in
                    let data = doc.data()
                    return Item(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "不明なアイテム",
                        purchased: data["purchased"] as? Bool ?? false,
                        order: data["order"] as? Int ?? 0,
                        location: data["location"] as? String ?? "未登録",
                        url: data["url"] as? String ?? "",
                        quantity: data["quantity"] as? Int ?? 1,
                        deadline: data["deadline"] as? String ?? "未設定",
                        memo: data["memo"] as? String ?? "",
                        registeredAt: data["registeredAt"] as? String ?? "",
                        registrant: data["registrant"] as? String ?? "",
                        buyer: data["buyer"] as? String,
                        purchasedAt: data["purchasedAt"] as? String,
                        groupId: group.id
                    )
                }
                fetchedItems.append(contentsOf: items)
            }
            
            DispatchQueue.main.async {
                self.items = fetchedItems
            }
            
        } catch {
            print("データの取得に失敗しました: \(error.localizedDescription)")
        }
    }
}
