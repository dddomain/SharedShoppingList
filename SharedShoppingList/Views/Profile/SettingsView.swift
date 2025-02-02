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
                UserInfoManager.fetchUserInfo { name, display, mail, birth in
                    self.userName = name
                    self.displayName = display
                    self.email = mail
                    self.birthdate = birth
                    self.isLoading = false
                }
            }
        }
    }
}
