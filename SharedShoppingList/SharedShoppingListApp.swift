import SwiftUI
import Firebase
import FirebaseMessaging

@main
struct SharedShoppingListApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SessionManager())
        }
    }
}
