//ContentView.swift
import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        if session.isLoggedIn {
            TabView {
                NavigationView {
                    GroupListView()
                }
                .tabItem {
                    Label("ホーム", systemImage: "house")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SessionManager())
    }
}
