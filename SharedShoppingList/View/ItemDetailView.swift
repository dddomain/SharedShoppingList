//ItemDetailView.swift

import SwiftUI
import FirebaseFirestore

struct ItemDetailView: View {
    let group: Group
    let item: Item
    @State private var itemDetails: [String: Any] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DetailRow(label: "名前", value: itemDetails["name"] as? String ?? "不明")
            DetailRow(label: "個数", value: "\(itemDetails["quantity"] as? Int ?? 1)")
            DetailRow(label: "購入状態", value: itemDetails["purchased"] as? Bool == true ? "購入済み" : "未購入")
            DetailRow(label: "購入場所", value: itemDetails["location"] as? String ?? "未登録")
            DetailRow(label: "購入期限", value: itemDetails["deadline"] as? String ?? "未登録")
            DetailRow(label: "登録者", value: itemDetails["registrant"] as? String ?? "不明")
            DetailRow(label: "登録日時", value: itemDetails["registeredAt"] as? String ?? "不明")
            DetailRow(label: "購入者", value: itemDetails["buyer"] as? String ?? "不明")
            DetailRow(label: "購入日時", value: itemDetails["purchasedAt"] as? String ?? "不明")
            DetailRow(label: "メモ", value: itemDetails["memo"] as? String ?? "なし")

            Spacer()
        }
        .padding()
        .navigationTitle(item.name)
        .onAppear {
            fetchItemDetails()
        }
    }

    func fetchItemDetails() {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).collection("items").document(item.id).getDocument { document, error in
            if let error = error {
                itemDetails = [:]
                itemDetails["error"] = "データ取得に失敗しました"
            } else {
                print("アイテムの詳細取得に失敗しました: \(error?.localizedDescription ?? "不明なエラー")")
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.bold)
            Spacer()
            Text(value)
        }
    }
}

