//SignUpView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

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
    @State private var isProcessing = false  // 処理中フラグ

    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("新規登録")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                SwiftUI.Group {
                    TextField("姓", text: $firstName)
                    TextField("名", text: $lastName)
                    TextField("表示名", text: $displayName)
                    DatePicker("誕生日", selection: $birthdate, displayedComponents: .date)
                    TextField("メールアドレス", text: $email)
                        .keyboardType(.emailAddress)
                    SecureField("パスワード", text: $password)
                    SecureField("パスワード確認", text: $confirmPassword)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    registerUser()
                }) {
                    Text("アカウントを作成")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid() ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid() || isProcessing)
                .padding()
            }
            .padding()
        }
        .navigationTitle("")
    }

    // ユーザー登録処理
    private func registerUser() {
        guard password == confirmPassword else {
            errorMessage = "パスワードが一致しません。"
            return
        }

        isProcessing = true
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let user = authResult?.user {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                changeRequest.commitChanges { error in
                    if error != nil {
                        errorMessage = "表示名の更新に失敗しましたが、アカウントは作成されました。"
                    }
                    // 🔥 FCM トークンを Firestore に保存
                    saveUserInfo(user)
                }
            } else if let error = error {
                errorMessage = "アカウント作成に失敗しました: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }

    // Firestoreにユーザー情報 + FCMトークンを保存
    private func saveUserInfo(_ user: User) {
        let db = Firestore.firestore()
        Messaging.messaging().token { token, error in
            if let error = error {
                print("⚠️ FCM トークン取得エラー: \(error.localizedDescription)")
            }
            
            let userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "displayName": displayName,
                "birthdate": Timestamp(date: birthdate),
                "email": email,
                "fcmToken": token ?? "" // 🔥 FCMトークンを Firestore に保存（取得失敗時は空）
            ]
            
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    errorMessage = "ユーザー情報の保存に失敗しました: \(error.localizedDescription)"
                    print("Firestore書き込みエラー: \(error)")
                } else {
                    isLoggedIn = true
                    print("✅ Firestore にユーザー情報と FCM トークンを保存しました: \(token ?? "なし")")
                }
                isProcessing = false
            }
        }
    }

    // 入力バリデーション
    private func isFormValid() -> Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
        !firstName.isEmpty && !lastName.isEmpty && !displayName.isEmpty &&
        password.count >= 6
    }
}
