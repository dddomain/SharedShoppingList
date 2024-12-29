import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GroupListView: View {
    @State private var groups: [Group] = []
    @State private var newGroupName: String = ""
    @State private var showAddGroupPopup: Bool = false
    @EnvironmentObject var session: SessionManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            List(groups) { group in
                NavigationLink(destination: ItemListView(group: group)) {
                    Text(group.name)
                }
            }
            .navigationTitle("グループ")
            .onAppear {
                fetchUserGroups()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ログアウト") {
                        try? Auth.auth().signOut()
                        session.isLoggedIn = false
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddGroupPopup = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddGroupPopup) {
            VStack {
                Text("新しいグループを作成")
                    .font(.headline)
                    .padding()
                TextField("グループ名", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("作成") {
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

    // グループをFirestoreに追加（作成ユーザー情報を含む）
    func addGroup() {
        guard !newGroupName.isEmpty, let userId = session.user?.uid else { return }
        let db = Firestore.firestore()
        let newGroupRef = db.collection("groups").document()
        let groupData: [String: Any] = [
            "name": newGroupName,
            "createdBy": userId
        ]
        newGroupRef.setData(groupData) { error in
            if error == nil {
                groups.append(Group(id: newGroupRef.documentID, name: newGroupName))
                newGroupName = ""
            }
        }
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
                            name: data["name"] as? String ?? "名前不明"
                        )
                    }
                }
            }
    }
}
