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
        ZStack {
            Color(UIColor.systemGray6)
                .edgesIgnoringSafeArea(.all) // ライトグレーの背景を全画面に適用
            
            VStack {
                Text("新規登録")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                TextField("姓", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                TextField("名", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                TextField("表示名", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                DatePicker("誕生日", selection: $birthdate, displayedComponents: .date)
                    .padding()
                TextField("メールアドレス", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                SecureField("パスワード", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                SecureField("パスワード確認", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button("アカウントを作成") {
                    if password == confirmPassword {
                        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                            if let user = authResult?.user {
                                let changeRequest = user.createProfileChangeRequest()
                                changeRequest.displayName = "\(firstName) \(lastName)"
                                changeRequest.commitChanges { error in
                                    if let error = error {
                                        errorMessage = "表示名の更新に失敗しました: \(error.localizedDescription)"
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
                                                errorMessage = "ユーザー情報の保存に失敗しました: \(error.localizedDescription)"
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
                        errorMessage = "パスワードが一致しません。"
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("")
    }
}
