import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationView {
            if session.isLoggedIn {
                GroupListView()
            } else {
                LoginView(isLoggedIn: $session.isLoggedIn)
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
