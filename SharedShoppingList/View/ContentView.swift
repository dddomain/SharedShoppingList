//ContentView.swift
import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        TabView {
            NavigationView {
                if session.isLoggedIn {
                    GroupListView()
                } else {
                    LoginView(isLoggedIn: $session.isLoggedIn)
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .previewDevice("iPhone 14")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SessionManager())
    }
}
