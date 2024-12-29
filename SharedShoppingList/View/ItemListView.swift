// ItemListView.swift
import SwiftUI
import FirebaseFirestore

enum AlertType {
    case purchase
    case unpurchase
    case none
}

struct ItemListView: View {
    let group: Group
    @State private var items: [Item] = []
    @State private var newItemName: String = ""
    @State private var showAddItemPopup: Bool = false
    @State private var alertType: AlertType = .none
    @State private var selectedItem: Item? = nil

    var body: some View {
        VStack {
            if items.isEmpty {
                Text("＋ボタンから買い物リストを追加しましょう")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(items) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if item.purchased {
                                Image(systemName: "checkmark.circle.fill")
                            } else {
                                Image(systemName: "circle")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = item
                            if item.purchased {
                                alertType = .unpurchase
                            } else {
                                alertType = .purchase
                            }
                        }
                    }
                    .onDelete(perform: deleteItem)
                    .onMove(perform: moveItem)
                }
            }
        }
        .navigationTitle(group.name)
        .onAppear {
            fetchItems()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddItemPopup = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddItemPopup) {
            VStack {
                Text("新しいアイテムを追加")
                    .font(.headline)
                    .padding()
                TextField("アイテム名", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("追加") {
                    addItem()
                    showAddItemPopup = false
                }
                .padding()
                Button("キャンセル") {
                    showAddItemPopup = false
                }
                .padding()
            }
            .padding()
        }
        .alert(item: $selectedItem) { item in
            switch alertType {
            case .purchase:
                return Alert(
                    title: Text("購入確認"),
                    message: Text("購入済みとしてメンバーに通知しますか？"),
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

    func fetchItems() {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).collection("items").order(by: "order").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let fetchedItems = documents.map { doc -> Item in
                    let data = doc.data()
                    return Item(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        purchased: data["purchased"] as? Bool ?? false,
                        order: data["order"] as? Int ?? 0
                    )
                }
                DispatchQueue.main.async {
                    items = fetchedItems
                }
            }
        }
    }

    func addItem() {
        guard !newItemName.isEmpty else { return }
        let db = Firestore.firestore()
        let newItemRef = db.collection("groups").document(group.id).collection("items").document()
        let maxOrder = (items.max(by: { $0.order < $1.order })?.order ?? 0) + 1
        let itemData: [String: Any] = [
            "name": newItemName,
            "purchased": false,
            "order": maxOrder
        ]
        newItemRef.setData(itemData) { error in
            if error == nil {
                items.append(Item(id: newItemRef.documentID, name: newItemName, purchased: false, order: maxOrder))
                newItemName = ""
            }
        }
    }

    func toggleItem(_ item: Item, toPurchased: Bool) {
        let db = Firestore.firestore()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let previousState = items[index].purchased
        items[index].purchased = toPurchased

        db.collection("groups").document(group.id).collection("items").document(item.id).updateData([
            "purchased": toPurchased
        ]) { error in
            if let error = error {
                print("Error updating item: \(error.localizedDescription)")
                items[index].purchased = previousState
            }
            selectedItem = nil
        }
    }
    
    func deleteItem(at offsets: IndexSet) {
        let db = Firestore.firestore()
        offsets.forEach { index in
            let item = items[index]
            db.collection("groups").document(group.id).collection("items").document(item.id).delete { error in
                if let error = error {
                    print("Error deleting item: \(error.localizedDescription)")
                } else {
                    items.remove(at: index)
                }
            }
        }
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        let db = Firestore.firestore()
        let batch = db.batch()
        for (index, item) in items.enumerated() {
            let ref = db.collection("groups").document(group.id).collection("items").document(item.id)
            batch.updateData(["order": index], forDocument: ref)
        }
        batch.commit { error in
            if let error = error {
                print("Error updating item order: \(error.localizedDescription)")
            }
        }
    }

}
