import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var user: User? = nil
    @Published var fcmToken: String = ""

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.user = user
                self?.isLoggedIn = true
                self?.registerFCMToken()
            } else {
                self?.isLoggedIn = false
            }
        }
    }

    func registerFCMToken() {
        Messaging.messaging().token { token, error in
            if let token = token {
                self.fcmToken = token
                if let userId = self.user?.uid {
                    let db = Firestore.firestore()
                    db.collection("users").document(userId).setData(["fcmToken": token], merge: true)
                }
            }
        }
    }
}
