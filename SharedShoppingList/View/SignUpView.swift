//SignUpView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var displayName = ""
    @State private var birthdate = Date()
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Display Name", text: $displayName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            DatePicker("Birthdate", selection: $birthdate, displayedComponents: .date)
                .padding()
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
                        if let user = authResult?.user {
                            let changeRequest = user.createProfileChangeRequest()
                            changeRequest.displayName = "\(firstName) \(lastName)"
                            changeRequest.commitChanges { error in
                                if let error = error {
                                    errorMessage = "Failed to update display name: \(error.localizedDescription)"
                                } else {
                                    let db = Firestore.firestore()
                                    db.collection("users").document(user.uid).setData([
                                        "firstName": firstName,
                                        "lastName": lastName,
                                        "displayName": displayName,
                                        "birthdate": Timestamp(date: birthdate),
                                        "email": email
                                    ]) { error in
                                        if let error = error {
                                            errorMessage = "Failed to save user data: \(error.localizedDescription)"
                                        } else {
                                            isLoggedIn = true
                                        }
                                    }
                                }
                            }
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
