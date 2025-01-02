import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @State private var items: [Item] = []
    @State private var groups: [String: Group] = [:]
    @State private var currentUserID: String? = Auth.auth().currentUser?.uid
    @State private var selectedItem: Item? = nil
    @State private var alertType: AlertType = .none

    @State private var userName: String = ""
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var birthdate: String = ""

    var body: some View {
        List {
            ForEach(items) { item in
                HStack {
                    Image(systemName: item.purchased ? "checkmark.circle.fill" : "circle")
                        .onTapGesture {
                            selectedItem = item
                            alertType = item.purchased ? .unpurchase : .purchase
                        }
                    NavigationLink(destination: ItemDetailView(group: groups[item.groupId ?? ""] ?? Group(id: "", name: "不明", inviteCode: ""), item: item)) {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            Text(groups[item.groupId ?? ""]?.name ?? "不明なグループ")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("買いに行きましょう")
        .onAppear {
            Task {
                await fetchUserGroupsAndItems()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Button(action: {
                        session.showProfile = true
                        UserInfoManager.fetchUserInfo { name, display, mail, birth in
                            self.userName = name
                            self.displayName = display
                            self.email = mail
                            self.birthdate = birth
                        }
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
                    HStack {
                        Image(systemName: "person.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $session.showProfile) {
            ProfileView(userName: userName, displayName: displayName, email: email, birthdate: birthdate)
        }
        .alert(item: $selectedItem) { item in
            switch alertType {
            case .purchase:
                return Alert(
                    title: Text("購入確認"),
                    message: Text("購入済みとしてマークしますか？"),
                    primaryButton: .default(Text("はい")) {
                        toggleItem(item, toPurchased: true)
                    },
                    secondaryButton: .cancel(Text("いいえ"))
                )
            case .unpurchase:
                return Alert(
                    title: Text("未購入に戻す確認"),
                    message: Text("未購入に戻しますか？"),
                    primaryButton: .default(Text("はい")) {
                        toggleItem(item, toPurchased: false)
                    },
                    secondaryButton: .cancel(Text("いいえ"))
                )
            case .none:
                return Alert(title: Text("エラー"))
            }
        }
    }

    // アイテムの購入状態を切り替え
    private func toggleItem(_ item: Item, toPurchased: Bool) {
        let db = Firestore.firestore()
        guard let groupId = item.groupId else { return }
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let previousState = items[index].purchased
        items[index].purchased = toPurchased

        db.collection("groups").document(groupId).collection("items").document(item.id).updateData([
            "purchased": toPurchased
        ]) { error in
            if let error = error {
                print("更新に失敗しました: \(error.localizedDescription)")
                items[index].purchased = previousState
            } else {
                // 購入済みアイテムを非表示にする
                items.removeAll { $0.purchased == true }
            }
            selectedItem = nil
        }
    }

    // Firestoreからグループと未購入アイテムを取得
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
                    inviteCode: data["inviteCode"] as? String ?? ""
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
