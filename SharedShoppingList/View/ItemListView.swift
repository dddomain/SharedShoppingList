import SwiftUI
import FirebaseFirestore
import FirebaseMessaging

struct ItemListView: View {
    let group: Group
    @State private var items: [Item] = []

    var body: some View {
        List(items) { item in
            HStack {
                Text(item.name)
                Spacer()
                if item.purchased {
                    Image(systemName: "checkmark.circle")
                }
            }
            .onTapGesture {
                toggleItem(item)
            }
        }
        .navigationTitle(group.name)
    }

    func toggleItem(_ item: Item) {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).collection("items").document(item.id).updateData([
            "purchased": !item.purchased
        ]) { error in
            if error == nil {
                sendNotification(for: item)
            }
        }
    }

    func sendNotification(for item: Item) {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                for document in documents {
                    if let token = document.data()["fcmToken"] as? String {
                        let message = [
                            "to": token,
                            "notification": [
                                "title": "購入済み",
                                "body": "\(item.name)が購入されました"
                            ]
                        ]
                        sendFCMRequest(with: message)
                    }
                }
            }
        }
    }

    func sendFCMRequest(with message: [String: Any]) {
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=YOUR_SERVER_KEY", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: message)
        
        URLSession.shared.dataTask(with: request).resume()
    }
}
