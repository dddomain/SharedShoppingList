// GroupListView.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GroupListView: View {
    @EnvironmentObject var session: SessionManager
    @State private var groups: [Group] = []
    @State private var newGroupName: String = ""
    @State private var showAddGroupPopup: Bool = false

    var body: some View {
        
            VStack {
                List {
                    ForEach(groups) { group in
                        NavigationLink(destination: ItemListView(group: group)) {
                            Text(group.name)
                        }
                    }
                    .onDelete(perform: deleteGroup)
                    .onMove(perform: moveGroup)
                }

                Button("グループを追加") {
                    showAddGroupPopup = true
                }
                .padding()
            }
            .navigationTitle("グループ一覧")
            .toolbar {
                EditButton()
            }
            .onAppear {
                fetchGroups()
            }
        .sheet(isPresented: $showAddGroupPopup) {
            VStack {
                Text("新しいグループを追加")
                    .font(.headline)
                    .padding()
                TextField("グループ名", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("追加") {
                    addGroup()
                    showAddGroupPopup = false
                }
                .padding()
                Button("キャンセル") {
                    showAddGroupPopup = false
                }
                .padding()
            }
            .padding()
        }
    }

    func fetchGroups() {
        let db = Firestore.firestore()
        db.collection("groups").order(by: "order").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                groups = documents.map { doc in
                    let data = doc.data()
                    return Group(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        order: data["order"] as? Int ?? 0,
                        inviteCode: data["invidateCode"] as? String ?? ""
                    )
                }
            }
        }
    }

    func addGroup() {
        guard !newGroupName.isEmpty else { return }
        let db = Firestore.firestore()
        let newGroupRef = db.collection("groups").document()
        let inviteCode = generateInviteCode()
        let maxOrder = (groups.max(by: { $0.order < $1.order })?.order ?? 0) + 1
        let groupData: [String: Any] = [
            "inviteCode": inviteCode,
            "name": newGroupName,
            "order": maxOrder
        ]
        newGroupRef.setData(groupData) { error in
            if error == nil {
                groups.append(Group(id: newGroupRef.documentID, name: newGroupName, order: maxOrder, inviteCode: generateInviteCode()))
                newGroupName = ""
            }
        }
    }

    func deleteGroup(at offsets: IndexSet) {
        let db = Firestore.firestore()
        offsets.forEach { index in
            let group = groups[index]
            db.collection("groups").document(group.id).delete { error in
                if error == nil {
                    groups.remove(at: index)
                }
            }
        }
    }

    func moveGroup(from source: IndexSet, to destination: Int) {
        groups.move(fromOffsets: source, toOffset: destination)
        let db = Firestore.firestore()
        let batch = db.batch()
        for (index, group) in groups.enumerated() {
            let ref = db.collection("groups").document(group.id)
            batch.updateData(["order": index], forDocument: ref)
        }
        batch.commit { error in
            if let error = error {
                print("Error updating group order: \(error.localizedDescription)")
            }
        }
    }
    
    // 8桁のランダムな招待コードを生成
    func generateInviteCode() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in letters.randomElement()! })
    }

    // Firestoreからログインユーザーが作成したグループを取得
    func fetchUserGroups() {
        guard let userId = session.user?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("groups")
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    groups = documents.map { doc in
                        let data = doc.data()
                        return Group(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "名前不明" ,
                            order: data["order"] as? Int ?? 0,
                            inviteCode: data["invidateCode"] as? String ?? ""
                        )
                    }
                }
            }
    }
}
