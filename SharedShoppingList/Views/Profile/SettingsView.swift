import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

struct SettingsView: View {
    @ObservedObject var userManager = UserInfoManager.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @State private var showDeleteAccountAlert = false
    @State private var showLogoutAlert = false
    @EnvironmentObject var session: SessionManager

    var body: some View {
        Form {
            Section(header: Text("アカウント")) {
                NavigationLink(destination: ProfileView(
                    userName: userManager.userName,
                    displayName: userManager.displayName,
                    email: userManager.email,
                    birthdate: userManager.birthdate
                )) {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(userManager.colorTheme)
                        Text("プロフィール")
                    }
                }
            }

            Section(header: Text("通知")) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(userManager.colorTheme)
                    Toggle("プッシュ通知を受け取る", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) {
                            handleNotificationChange($0)
                        }
                }
            }

            Section(header: Text("テーマ")) {
                HStack {
                    Image(systemName: userManager.storedThemeMode == "Dark" ? "moon.stars.fill" : "sun.max.fill")
                        .foregroundColor(userManager.colorTheme)
                    Picker("画面設定", selection: $userManager.storedThemeMode) {
                        Text("ライト").tag("Light")
                        Text("ダーク").tag("Dark")
                        Text("システム").tag("System")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: userManager.storedThemeMode) {
                        userManager.saveThemeMode($0)
                    }
                }
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(userManager.colorTheme)
                    Picker("あなたのカラー", selection: $userManager.storedColor) {
                        ForEach(["blue", "red", "green", "yellow", "orange", "purple", "pink"], id: \.self) { color in
                            Text(color.capitalized)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: userManager.storedColor) {
                        userManager.saveUserColor($0)
                    }
                }
            }

            Section(header: Text("その他")) {
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Image(systemName: "lock.doc.fill")
                            .foregroundColor(userManager.colorTheme)
                        Text("プライバシーポリシー")
                    }
                }
                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(userManager.colorTheme)
                        Text("利用規約")
                    }
                }
            }

            Section(header: Text("ログアウト・退会")) {
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.black)  // 黒アイコン
                        Text("ログアウト")
                            .foregroundColor(.primary)  // 黒文字（デフォルト）
                    }
                }
                .alert(isPresented: $showLogoutAlert) {
                    Alert(
                        title: Text("ログアウト確認"),
                        message: Text("ログアウトしますか？"),
                        primaryButton: .destructive(Text("ログアウト")) {
                            logout()
                        },
                        secondaryButton: .cancel()
                    )
                }

                Button(action: {
                    showDeleteAccountAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)  // 赤アイコン
                        Text("アカウント削除")
                            .foregroundColor(.red)  // 赤文字
                    }
                }
                .alert(isPresented: $showDeleteAccountAlert) {
                    Alert(
                        title: Text("アカウント削除"),
                        message: Text("アカウントを削除すると、すべてのデータが失われ復旧できません。本当に削除しますか？"),
                        primaryButton: .destructive(Text("削除")) {
                            deleteAccount()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .navigationTitle("設定")
        .onAppear {
            userManager.loadUserInfo()
        }
    }

    private func handleNotificationChange(_ enabled: Bool) {
        if enabled {
            NotificationManager.shared.configure()
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        saveNotificationSetting(enabled)
    }

    private func saveNotificationSetting(_ enabled: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).setData(["notificationsEnabled": enabled], merge: true)
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            session.isLoggedIn = false
        } catch {
            print("ログアウトに失敗しました: \(error.localizedDescription)")
        }
    }

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid
        let db = Firestore.firestore()

        // 1. Firestoreからユーザー情報を削除
        db.collection("users").document(userId).delete { error in
            if let error = error {
                print("ユーザーデータ削除エラー: \(error.localizedDescription)")
                return
            }
            print("ユーザー情報を削除しました")

            // 2. グループからユーザーを削除
            db.collection("groups").whereField("members", arrayContains: userId).getDocuments { snapshot, error in
                if let error = error {
                    print("グループデータ取得エラー: \(error.localizedDescription)")
                    return
                }

                let batch = db.batch()
                snapshot?.documents.forEach { document in
                    let groupRef = db.collection("groups").document(document.documentID)
                    batch.updateData(["members": FieldValue.arrayRemove([userId])], forDocument: groupRef)
                }
                batch.commit { batchError in
                    if let batchError = batchError {
                        print("グループからの削除エラー: \(batchError.localizedDescription)")
                    } else {
                        print("グループからのユーザー削除完了")
                    }

                    // 3. Firebase Authentication からユーザーを削除
                    user.delete { authError in
                        if let authError = authError {
                            print("アカウント削除エラー: \(authError.localizedDescription)")
                        } else {
                            print("アカウントを削除しました")
                            session.isLoggedIn = false
                        }
                    }
                }
            }
        }
    }
}
