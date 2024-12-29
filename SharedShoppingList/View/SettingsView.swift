// SettingsView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @State private var userName: String = ""
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var birthdate: String = ""
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("アカウント")) {
                    NavigationLink(destination: ProfileView(userName: userName, displayName: displayName, email: email, birthdate: birthdate)) {
                        Text("プロフィール")
                    }
                    Text("通知")
                }
                
                Section(header: Text("設定")) {
                    Text("テーマ")
                    Text("言語")
                }
            }
            .navigationTitle("設定")
            .onAppear {
                fetchUserInfo()
            }
        }
    }

    func fetchUserInfo() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                userName = "\(data?["firstName"] as? String ?? "") \(data?["lastName"] as? String ?? "")"
                displayName = data?["displayName"] as? String ?? ""
                email = data?["email"] as? String ?? ""
                if let timestamp = data?["birthdate"] as? Timestamp {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    birthdate = dateFormatter.string(from: timestamp.dateValue())
                }
            }
            isLoading = false
        }
    }
}

struct ProfileView: View {
    var userName: String
    var displayName: String
    var email: String
    var birthdate: String

    var body: some View {
        Form {
            Section(header: Text("ユーザー情報")) {
                HStack {
                    Text("名前")
                    Spacer()
                    Text(userName)
                }
                HStack {
                    Text("表示名")
                    Spacer()
                    Text(displayName)
                }
                HStack {
                    Text("メールアドレス")
                    Spacer()
                    Text(email)
                }
                HStack {
                    Text("誕生日")
                    Spacer()
                    Text(birthdate)
                }
            }
        }
        .navigationTitle("プロフィール")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
