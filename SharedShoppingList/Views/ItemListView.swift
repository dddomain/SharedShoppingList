// ItemListView.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum AlertType {
    case purchase
    case unpurchase
    case none
}

struct ItemListView: View {
    let group: Group
    @Environment(\.editMode) private var editMode
    @State private var items: [Item] = []
    @State private var inviteCode: String = ""
    @State private var newItemName: String = ""
    @State private var newItemLocation: String = ""
    @State private var newItemURL: String = ""
    @State private var newItemQuantity: String = "1"
    @State private var newItemDeadline: Date = Date()
    @State private var newItemMemo: String = ""
    @State private var showAddItemPopup: Bool = false
    @State private var shouldSetDeadline: Bool = false
    @State private var selectedImage: UIImage? = nil
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
                        ItemRowView(
                            item: item,
                            groupName: group.name,
                            members: group.members,
                            context: "list"  // ItemListViewでは"list"を渡す
                        ) {
                            selectedItem = item
                            alertType = item.purchased ? .unpurchase : .purchase
                        }
                    }
                    .onDelete(perform: deleteItem)
                }
            }
        }
        .navigationTitle(group.name)
        .onAppear {
            fetchItems()
            fetchInviteCode()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if editMode?.wrappedValue == .active {
                        editMode?.wrappedValue = .inactive
                    } else {
                        editMode?.wrappedValue = .active
                    }
                }) {
                    Image(systemName: editMode?.wrappedValue == .active ? "checkmark" : "pencil")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddItemPopup = true
                }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: GroupDetailView(group: group)) {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
        .sheet(isPresented: $showAddItemPopup) {
            NavigationView {
                VStack {
                    Form {
                        // 基本情報セクション
                        Section(header: Text("基本情報").font(.headline)) {
                            TextField("アイテム名", text: $newItemName)
                            
                            TextField("購入できる場所", text: $newItemLocation)
                            
                            TextField("URL", text: $newItemURL)
                                .keyboardType(.URL)
                            
                            TextField("個数", text: $newItemQuantity)
                                .keyboardType(.numberPad)
                        }
                        
                        // 購入期限セクション
                        Section(header: Text("購入期限").font(.headline)) {
                            Picker("購入期限の設定", selection: $shouldSetDeadline) {
                                Text("設定しない").tag(false)
                                Text("設定する").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            if shouldSetDeadline {
                                DatePicker("期限日", selection: $newItemDeadline, displayedComponents: .date)
                            }
                        }
                    }
                    
                    // 追加・キャンセルボタンをフォーム外に配置
                    VStack {
                        Button(action: {
                            addItem()
                            showAddItemPopup = false
                        }) {
                            HStack {
                                Spacer()
                                Text("追加")
                                    .bold()
                                Spacer()
                            }
                            .padding()
                            .background(newItemName.isEmpty || newItemQuantity.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(newItemName.isEmpty || newItemQuantity.isEmpty)
                        
                        Button("キャンセル") {
                            showAddItemPopup = false
                        }
                        .foregroundColor(.red)
                        .padding(10)
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("新しいアイテムを追加")
                .navigationBarItems(leading: Button("閉じる") {
                    showAddItemPopup = false
                })
            }
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

    func fetchInviteCode() {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).getDocument { document, error in
            if let document = document, document.exists {
                inviteCode = document.data()? ["inviteCode"] as? String ?? ""
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
                DispatchQueue.main.async {
                    items = fetchedItems
                }
            }
        }
    }

    func addItem() {
        guard !newItemName.isEmpty, let quantity = Int(newItemQuantity), quantity > 0 else {
            print("入力データが不正です。")
            return
        }
        
        let db = Firestore.firestore()
        let newItemRef = db.collection("groups").document(group.id).collection("items").document()
        let maxOrder = (items.max(by: { $0.order < $1.order })?.order ?? 0) + 1
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var itemData: [String: Any] = [
            "name": newItemName,
            "purchased": false,
            "order": maxOrder,
            "location": newItemLocation,
            "url": newItemURL,
            "quantity": quantity,
            "deadline": Timestamp(date: newItemDeadline),  // Timestamp型で保存
            "memo": newItemMemo,
            "registeredAt": formatter.string(from: Date()),
            "registrant": Auth.auth().currentUser?.uid ?? "unknown",
            "groupId": group.id
        ]
        
        // 期限が設定されている場合のみ追加
        if shouldSetDeadline {
            itemData["deadline"] = Timestamp(date: newItemDeadline)
        } else {
            itemData["deadline"] = nil
        }
        
        newItemRef.setData(itemData) { error in
            if let error = error {
                print("Firestoreへの保存に失敗: \(error.localizedDescription)")
            } else {
                items.append(Item(
                    id: newItemRef.documentID,
                    name: newItemName,
                    purchased: false,
                    order: maxOrder,
                    location: newItemLocation,
                    url: newItemURL,
                    quantity: quantity,
                    deadline: Timestamp(date: newItemDeadline),
                    memo: newItemMemo,
                    registeredAt: Date(),
                    registrant: Auth.auth().currentUser?.uid ?? "unknown",
                    buyer: nil,
                    purchasedAt: nil,
                    groupId: group.id
                ))
                
                // フォームの入力値をリセット
                resetForm()
            }
        }
    }

    // フォームリセット関数
    func resetForm() {
        newItemName = ""
        newItemLocation = ""
        newItemURL = ""
        newItemQuantity = "1"
        newItemDeadline = Date()
        newItemMemo = ""
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
