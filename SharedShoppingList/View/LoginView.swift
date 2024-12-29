import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Login") {
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if authResult != nil {
                        isLoggedIn = true
                    }
                }
            }
            .padding()

            Button("Sign Up") {
                showSignUp = true
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView(isLoggedIn: $isLoggedIn)
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
