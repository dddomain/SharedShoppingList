import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @ObservedObject var userManager = UserInfoManager.shared  // 🔥 UserInfoManager を使用

    @State private var items: [Item] = []
    @State private var groups: [String: Group] = [:]
    @State private var currentUserID: String? = Auth.auth().currentUser?.uid
    @State private var selectedItem: Item? = nil
    @State private var alertType: AlertType = .none

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    let groupName = groups[item.groupId]?.name ?? "不明なグループ"
                    let groupMembers = groups[item.groupId]?.members ?? []

                    ItemRowView(item: item, groupName: groupName, members: groupMembers, context: "home") {
                        selectedItem = item
                        alertType = item.purchased ? .unpurchase : .purchase
                    }
                }
            }
            .navigationTitle("買いに行きましょう")
            .onAppear {
                Task {
                    await fetchUserGroupsAndItems()
                }
            }
            .toolbar {  // 🔥 `.toolbar(content:)` に変更
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: {
                            userManager.loadUserInfo()  // 🔥 `fetchUserInfo()` → `loadUserInfo()`
                            session.showProfile = true
                        }) {
                            Label("プロフィールを見る", systemImage: "person")
                        }
                        Button(action: {
                            do {
                                try Auth.auth().signOut()
                                session.isLoggedIn = false
                            } catch {
                                print("ログアウトに失敗しました: \(error.localizedDescription)")
                            }
                        }) {
                            Label("ログアウトする", systemImage: "arrow.right.circle")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $session.showProfile) {
                ProfileView(
                    userName: userManager.userName,
                    displayName: userManager.displayName,
                    email: userManager.email,
                    birthdate: userManager.birthdate
                )
            }
        }
    }

    // Firestore からグループとアイテムを取得
    private func fetchUserGroupsAndItems() async {
        guard let userID = currentUserID else { return }
        let db = Firestore.firestore()

        do {
            let groupSnapshot = try await db.collection("groups")
                .whereField("members", arrayContains: userID)
                .getDocuments()
            
            let fetchedGroups = groupSnapshot.documents.map { doc -> Group in
                let data = doc.data()
                return Group(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    inviteCode: data["inviteCode"] as? String ?? "",
                    members: data["members"] as? [String] ?? []
                )
            }
            
            DispatchQueue.main.async {
                self.groups = Dictionary(uniqueKeysWithValues: fetchedGroups.map { ($0.id, $0) })
            }
            
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
                        name: data["name"] as? String ?? "",
                        purchased: data["purchased"] as? Bool ?? false,
                        order: data["order"] as? Int ?? 0,
                        location: data["location"] as? String ?? "",
                        url: data["url"] as? String ?? "",
                        quantity: data["quantity"] as? Int ?? 1,
                        deadline: data["deadline"] as? Timestamp ?? nil,
                        memo: data["memo"] as? String ?? "",
                        registeredAt: data["registeredAt"] as? Date ?? Date(),
                        registrant: data["registrant"] as? String ?? "",
                        buyer: data["buyer"] as? String,
                        purchasedAt: data["purchasedAt"] as? Timestamp,
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
