
import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Create Account") {
                if password == confirmPassword {
                    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                        if authResult != nil {
                            isLoggedIn = true
                        } else if let error = error {
                            errorMessage = error.localizedDescription
                        }
                    }
                } else {
                    errorMessage = "Passwords do not match."
                }
            }
            .padding()
        }
        .navigationTitle("Sign Up")
        .padding()
    }
}
