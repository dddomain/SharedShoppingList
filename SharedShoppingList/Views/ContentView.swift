import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject var session: SessionManager
    @ObservedObject var userManager = UserInfoManager.shared  // 🔥 カラー設定を監視

    var body: some View {
        ZStack {
            userManager.colorTheme.edgesIgnoringSafeArea(.all)  // 🔥 背景色を適用

            if session.isLoggedIn {
                TabView {
                    NavigationView {
                        HomeView()
                    }
                    .tabItem {
                        Label("ホーム", systemImage: "house")
                    }

                    NavigationView {
                        GroupListView()
                    }
                    .tabItem {
                        Label("リスト", systemImage: "list.dash")
                    }

                    NavigationView {
                        SettingsView()
                    }
                    .tabItem {
                        Label("設定", systemImage: "gear")
                    }
                }
                .accentColor(userManager.colorTheme) // 🔥 タブバーの色を適用
            } else {
                LoginView(isLoggedIn: $session.isLoggedIn)
            }
        }
        .onAppear {
            userManager.loadUserInfo()  // 🔥 Firestore からユーザーのカラーを取得
        }
        .preferredColorScheme(userManager.colorTheme == .blue ? .light : .dark) // 🔥 UI モード適用
    }
}
