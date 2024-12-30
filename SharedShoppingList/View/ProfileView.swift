//ProfileView
import SwiftUI
import FirebaseAuth

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
