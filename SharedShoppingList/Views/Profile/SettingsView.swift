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
                        Image(systemName: "person.circle")  // 🔥 プロフィールアイコン
                            .foregroundColor(userManager.colorTheme)
                        Text("プロフィール")
                    }
                }
            }

            Section(header: Text("通知")) {
                HStack {
                    Image(systemName: "bell")  // 🔥 通知アイコン
                        .foregroundColor(userManager.colorTheme)
                    Toggle("プッシュ通知を受け取る", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) {
                            handleNotificationChange($0)
                        }
                }
            }

            Section(header: Text("テーマ")) {
                HStack {
                    Image(systemName: userManager.storedThemeMode == "Dark" ? "moon.stars.fill" : "sun.max.fill")  // 🔥 昼夜のアイコン
                        .foregroundColor(userManager.colorTheme)
                    Picker("テーマ", selection: $userManager.storedThemeMode) {
                        Text("ライト").tag("Light").foregroundColor(.black)
                        Text("ダーク").tag("Dark").foregroundColor(.black)
                        Text("システム").tag("System").foregroundColor(.black)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: userManager.storedThemeMode) {
                        userManager.saveThemeMode($0) // 🔥 Firestore にテーマを保存し、UI に適用
                    }
                }
            }

            // 🔥 カラー設定
            Section(header: Text("アプリカラー")) {
                HStack {
                    Image(systemName: "paintpalette.fill")  // 🔥 ペイントアイコン
                        .foregroundColor(userManager.colorTheme)
                    Picker("カラーを選択", selection: $userManager.storedColor) {
                        ForEach(["blue", "red", "green", "yellow", "orange", "purple", "pink"], id: \.self) { color in
                            Text(color.capitalized)
                                .foregroundColor(.black)  // 🔥 ピッカーの文字を黒にする
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: userManager.storedColor) {
                        userManager.saveUserColor($0) // 🔥 Firestore に新しいカラーを保存
                    }
                }
            }
        }
        .navigationTitle("設定")
        .onAppear {
            userManager.loadUserInfo() // 🔥 Firestore のデータを UI に適用
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
