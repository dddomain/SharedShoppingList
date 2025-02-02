import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

struct SettingsView: View {
    @ObservedObject var userManager = UserInfoManager.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("themeMode") private var themeMode: String = "System"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("アカウント")) {
                    NavigationLink(destination: ProfileView(
                        userName: userManager.userName,
                        displayName: userManager.displayName,
                        email: userManager.email,
                        birthdate: userManager.birthdate
                    )) {
                        Text("プロフィール")
                    }
                }

                Section(header: Text("通知")) {
                    Toggle("プッシュ通知を受け取る", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { value in
                            handleNotificationChange(value)
                        }
                }

                Section(header: Text("テーマ")) {
                    Picker("テーマ", selection: $themeMode) {
                        Text("ライト").tag("Light")
                        Text("ダーク").tag("Dark")
                        Text("システム").tag("System")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: themeMode) { _ in
                        applyTheme()
                    }
                }

                // 🔥 カラー設定
                Section(header: Text("アプリカラー")) {
                    Picker("カラーを選択", selection: $userManager.storedColor) {
                        ForEach(["blue", "red", "green", "yellow", "orange", "purple", "pink"], id: \.self) { color in
                            Text(color.capitalized)
                                .foregroundColor(ColorManager.getColor(from: color))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: userManager.storedColor) { newColor in
                        userManager.saveUserColor(newColor) // 🔥 Firestore に新しいカラーを保存
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                userManager.loadUserInfo() // 🔥 ユーザー情報 & カラー設定を適用
                applyTheme()
            }
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

    private func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        for window in windowScene.windows {
            switch themeMode {
            case "Light":
                window.overrideUserInterfaceStyle = .light
            case "Dark":
                window.overrideUserInterfaceStyle = .dark
            default:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}
