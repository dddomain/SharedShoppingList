import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

struct SettingsView: View {
    @ObservedObject var userManager = UserInfoManager.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

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
                        Image(systemName: "lock.doc.fill")  // 🔥 プライバシーポリシーアイコン
                            .foregroundColor(userManager.colorTheme)
                        Text("プライバシーポリシー")
                    }
                }
                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Image(systemName: "doc.text.fill")  // 🔥 利用規約アイコン
                            .foregroundColor(userManager.colorTheme)
                        Text("利用規約")
                    }
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
}
