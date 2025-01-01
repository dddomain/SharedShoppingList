
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var items: [Item] = []
    @State private var groups: [Group] = []

    var body: some View {
        Text("test")
//        List {
//            ForEach(items) { item in
//                VStack(alignment: .leading) {
//                    Text(item.name)
//                        .font(.headline)
//                    Text(item.groupName)
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//            }
//        }
//        .navigationTitle("すべての買い物リスト")
//        .onAppear {
//            fetchAllItems()
//        }
    }

    // Firestoreから全アイテムを取得
//    private func fetchAllItems() {
//        let db = Firestore.firestore()
//        db.collection("groups").getDocuments { snapshot, error in
//            if let documents = snapshot?.documents {
//                self.groups = documents.map { doc in
//                    let data = doc.data()
//                    return Group(
//                        id: doc.documentID,
//                        name: data["name"] as? String ?? "",
//                        inviteCode: data["inviteCode"] as? String ?? ""
//                    )
//                }
//
//                for group in groups {
//                    db.collection("groups").document(group.id).collection("items").getDocuments { itemSnapshot, error in
//                        if let itemDocuments = itemSnapshot?.documents {
//                            let fetchedItems = itemDocuments.map { itemDoc -> Item in
//                                let data = itemDoc.data()
//                                return Item(
//                                    id: itemDoc.documentID,
//                                    name: data["name"] as? String ?? "",
//                                    groupName: group.name
//                                )
//                            }
//                            DispatchQueue.main.async {
//                                self.items.append(contentsOf: fetchedItems)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
}
