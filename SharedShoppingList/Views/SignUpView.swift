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
                .textFieldStyle(RoundedBorderTextFieldStyle())  // 正しくViewに適用
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
                .disabled(!isFormValid() || isProcessing)  // バリデーションと処理中はボタン無効化
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
                // 表示名をAuthプロファイルに更新
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                changeRequest.commitChanges { error in
                    if error != nil {
                        errorMessage = "表示名の更新に失敗しましたが、アカウントは作成されました。"
                    }
                    // 表示名更新後にFirestoreへデータを保存
                    saveUserInfo(user)
                }
            } else if let error = error {
                errorMessage = "アカウント作成に失敗しました: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }

    // Firestoreにユーザー情報を保存
    private func saveUserInfo(_ user: User) {
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
                print("Firestore書き込みエラー: \(error)")  // エラー内容をログ出力
            } else {
                isLoggedIn = true
                print("ユーザー情報が正常に保存されました")
            }
            isProcessing = false
        }
    }

    // 入力バリデーション
    private func isFormValid() -> Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
        !firstName.isEmpty && !lastName.isEmpty && !displayName.isEmpty &&
        password.count >= 6
    }
}
