// GroupListView.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GroupListView: View {
    @EnvironmentObject var session: SessionManager
    @State private var groups: [Group] = []
    @State private var newGroupName: String = ""
    @State private var showAddGroupPopup: Bool = false
    @State private var inviteCodeInput: String = ""
    @State private var showJoinGroupPopup: Bool = false
    
    @State private var userName: String = ""
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var birthdate: String = ""
    
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack {
            List {
                ForEach(groups) { group in
                    NavigationLink(destination: ItemListView(group: group)) {
                        Text(group.name)
                        Text(group.members.count == 1 ? "自分のみ" : "\(group.members.count)人")
                            .font(.caption)
                            .foregroundColor(.gray)

                    }
                }
                .onDelete(perform: deleteGroup)
            }

            Button("グループを追加") {
                showAddGroupPopup = true
            }
            .padding()
            Button("招待コードで参加") {
                showJoinGroupPopup = true
            }
            .padding()
            .sheet(isPresented: $showJoinGroupPopup) {
                VStack {
                    Text("招待コードを入力")
                        .font(.headline)
                        .padding()
                    
                    TextField("招待コード", text: $inviteCodeInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.bottom)
                    }

                    Button("参加") {
                        joinGroupWithInviteCode()
                    }
                    .padding()

                    Button("キャンセル") {
                        showJoinGroupPopup = false
                        errorMessage = nil  // シートを閉じる際にエラーメッセージをリセット
                    }
                    .padding()
                }
                .padding()
            }
        }
        .navigationTitle("所属グループ")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Button(action: {
                        // プロフィール画面に遷移
                        session.showProfile = true
                        fetchUserInfo()
                    }) {
                        Label("プロフィールを見る", systemImage: "person")
                    }
                    Button(action: {
                        // ログアウト処理
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
        .onAppear {
            fetchGroups()
        }
        .sheet(isPresented: $session.showProfile) {
            ProfileView(userName: userName, displayName: displayName, email: email, birthdate: birthdate)
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

    // ユーザー情報を取得する関数
    func fetchUserInfo() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                userName = "\(data?["firstName"] as? String ?? "") \(data?["lastName"] as? String ?? "")"
                displayName = data?["displayName"] as? String ?? "未設定"
                email = data?["email"] as? String ?? "未設定"
                
                if let timestamp = data?["birthdate"] as? Timestamp {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    birthdate = dateFormatter.string(from: timestamp.dateValue())
                }
            }
        }
    }

    func fetchGroups() {
        guard let userId = session.user?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("groups")
            .whereField("members", arrayContains: userId)  // 自分がメンバーであるグループのみ取得
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    groups = documents.map { doc in
                        let data = doc.data()
                        return Group(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "",
                            inviteCode: data["inviteCode"] as? String ?? "",
                            members: data["members"] as? [String] ?? []
                        )
                    }
                } else {
                    print("グループの取得に失敗しました: \(error?.localizedDescription ?? "不明なエラー")")
                }
            }
    }

    func addGroup() {
        guard !newGroupName.isEmpty, let userId = session.user?.uid else { return }
        let db = Firestore.firestore()
        let newGroupRef = db.collection("groups").document()
        let inviteCode = generateInviteCode()
        let groupData: [String: Any] = [
            "inviteCode": inviteCode,
            "name": newGroupName,
            "members": [userId],  // 作成者をメンバーとして追加
            "createdBy": userId
        ]
        newGroupRef.setData(groupData) { error in
            if error == nil {
                groups.append(Group(id: newGroupRef.documentID, name: newGroupName, inviteCode: inviteCode))
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
                            inviteCode: data["inviteCode"] as? String ?? ""
                        )
                    }
                }
            }
    }

    func joinGroupWithInviteCode() {
        guard !inviteCodeInput.isEmpty, let userId = session.user?.uid else { return }
        
        // 6桁バリデーション
        guard inviteCodeInput.count == 8 else {
            errorMessage = "招待コードは8桁です。"
            return
        }

        let db = Firestore.firestore()
        
        db.collection("groups")
            .whereField("inviteCode", isEqualTo: inviteCodeInput)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("エラーが発生しました: \(error.localizedDescription)")
                    errorMessage = "エラーが発生しました。"
                    return
                }
                
                guard let documents = snapshot?.documents, let document = documents.first else {
                    errorMessage = "グループが見つかりません。"
                    return
                }

                let data = document.data()
                let groupId = document.documentID
                let groupName = data["name"] as? String ?? "不明なグループ"

                // すでに参加済みかチェック
                if let members = data["members"] as? [String], members.contains(userId) {
                    errorMessage = "すでに参加済みです。(\(groupName))"
                } else {
                    // 参加処理
                    joinGroup(groupId: groupId, userId: userId)
                }
            }
    }

    // グループに参加する処理
    func joinGroup(groupId: String, userId: String) {
        let db = Firestore.firestore()
        db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayUnion([userId])
        ]) { error in
            if error == nil {
                fetchGroups()
                inviteCodeInput = ""
                showJoinGroupPopup = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let alert = UIAlertController(title: "成功", message: "グループに参加しました。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController?.present(alert, animated: true)
                    }
                }
            } else {
                errorMessage = "グループへの参加に失敗しました。"
            }
        }
    }
    
    // Firestoreからユーザーの表示名を取得
    func fetchUserDisplayName(userId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let displayName = document.data()?["displayName"] as? String
                completion(displayName)
            } else {
                completion(nil)
            }
        }
    }
}
