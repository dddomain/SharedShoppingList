//LoginView
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .edgesIgnoringSafeArea(.all) // ライトグレーの背景を全画面に適用

            VStack {
                Text("ログイン")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)

                TextField("メールアドレス", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                SecureField("パスワード", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("ログイン") {
                    Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                        if authResult != nil {
                            isLoggedIn = true
                        } else {
                            print("ログインできませんでした。")
                        }
                    }
                }
                .padding()

                Button("新規登録") {
                    showSignUp = true
                }
                .sheet(isPresented: $showSignUp) {
                    SignUpView(isLoggedIn: $isLoggedIn)
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
