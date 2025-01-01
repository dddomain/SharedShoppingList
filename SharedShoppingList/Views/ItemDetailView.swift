import SwiftUI
import FirebaseFirestore

struct ItemDetailView: View {
    let group: Group
    let item: Item
    @State private var itemDetails: [String: Any] = [:]
    @State private var displayNames: [String: String] = [:]  // UIDとdisplayNameのマッピング

    var body: some View {
        List {
            Section(header: Text("アイテム詳細").font(.headline)) {
                DetailRow(label: "名前", value: itemDetails["name"] as? String ?? "")
                DetailRow(label: "個数", value: "\(itemDetails["quantity"] as? Int ?? 1)")
                DetailRow(label: "購入状態", value: itemDetails["purchased"] as? Bool == true ? "購入済み" : "未購入")
            }

            Section(header: Text("購入情報").font(.headline)) {
                DetailRow(label: "購入できる場所", value: itemDetails["location"] as? String ?? "")
                DetailRow(label: "購入期限", value: itemDetails["deadline"] as? String ?? "")
                DetailRow(label: "購入者", value: displayNames[itemDetails["buyer"] as? String ?? ""] ?? "")
                DetailRow(label: "購入日時", value: itemDetails["purchasedAt"] as? String ?? "")
            }

            Section(header: Text("登録情報").font(.headline)) {
                DetailRow(label: "登録者", value: displayNames[itemDetails["registrant"] as? String ?? ""] ?? "")
                DetailRow(label: "登録日時", value: itemDetails["registeredAt"] as? String ?? "")
                DetailRow(label: "メモ", value: itemDetails["memo"] as? String ?? "")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(item.name)
        .onAppear {
            fetchItemDetails()
        }
    }

    // アイテムの詳細を取得しつつdisplayNameも取得
    func fetchItemDetails() {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).collection("items").document(item.id).getDocument { document, error in
            if let document = document, document.exists {
                itemDetails = document.data() ?? [:]
                fetchDisplayNames()
            } else {
                itemDetails = [:]
                itemDetails["error"] = "データ取得に失敗しました"
                print("アイテムの詳細取得に失敗しました: \(error?.localizedDescription ?? "不明なエラー")")
            }
        }
    }

    // FirestoreからユーザーのdisplayNameを取得
    func fetchDisplayNames() {
        let db = Firestore.firestore()
        let userIds = [
            itemDetails["buyer"] as? String,
            itemDetails["registrant"] as? String
        ].compactMap { $0 }

        for uid in userIds {
            db.collection("users").document(uid).getDocument { document, error in
                if let document = document, document.exists {
                    let displayName = document.data()?["displayName"] as? String ?? "未設定"
                    DispatchQueue.main.async {
                        displayNames[uid] = displayName
                    }
                } else {
                    DispatchQueue.main.async {
                        displayNames[uid] = "不明なユーザー"
                    }
                }
            }
        }
    }
}
