import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
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
                    Label("追加", systemImage: "plus.circle")
                }

                NavigationView {
                    SettingsView()
                }
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
            }
        } else {
            LoginView(isLoggedIn: $session.isLoggedIn)
        }
    }
}
