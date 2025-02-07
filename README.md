# 📦 **買い物リスト共有アプリ - Shared Shopping List**
**Firebase を活用したリアルタイム買い物リスト管理アプリ**

<img src="/スクリーンショット/4.png" width="30%" />
<img src="/スクリーンショット/5.png" width="30%" />
## 📌 **概要**
本アプリは、グループで買い物リストを共有・管理できるiOSアプリである。  
**Firebase Authentication**, **Firestore Database**, **Cloud Messaging (FCM)**, **Cloud Functions** を活用し、リアルタイムでデータの同期と通知を行う。

## 🎯 **主な機能**
- **📝 買い物リスト管理**  
  - グループごとのアイテム管理  
  - リアルタイム更新と並び替え  
  - 購入済みフラグの変更

- **👥 グループ管理**  
  - 招待コードによるグループ参加  
  - グループメンバーの一覧表示  
  - Firestoreを用いたアクセス制御

- **🔔 プッシュ通知 (FCM)**  
  - アイテム購入時にグループメンバーへ通知  
  - Firebase Cloud Functions を活用した通知送信  

- **🔑 ユーザー認証 (Firebase Auth)**  
  - メール・パスワード認証  
  - Firestore でユーザープロフィールを管理  

## 🛠 **使用技術**
### 📱 フロントエンド
- **SwiftUI** - モダンなUIフレームワーク
- **Combine** - データのリアクティブ管理
- **Firebase SDK** - Firestore, Authentication, Messaging 連携

### 🔥 バックエンド
- **Firebase Firestore** - NoSQL型データベース
- **Firebase Cloud Functions** - プッシュ通知の送信
- **Firebase Authentication** - ユーザー管理
- **Firebase Cloud Messaging (FCM)** - リアルタイム通知

---

## 🔧 **プロジェクト構成**
```
📦 SharedShoppingList
 ┣ 📂 Views             # SwiftUIの画面コンポーネント
 ┃ ┣ 📄 ContentView.swift
 ┃ ┣ 📄 HomeView.swift
 ┃ ┣ 📄 GroupListView.swift
 ┃ ┣ 📄 ItemListView.swift
 ┃ ┣ 📄 ItemDetailView.swift
 ┃ ┣ 📄 ProfileView.swift
 ┃ ┣ 📄 SettingsView.swift
 ┣ 📂 Models           # データモデル
 ┃ ┣ 📄 Item.swift
 ┃ ┣ 📄 Group.swift
 ┣ 📂 Managers        # ユーザー・セッション管理
 ┃ ┣ 📄 SessionManager.swift
 ┃ ┣ 📄 UserInfoManager.swift
 ┃ ┣ 📄 NotificationManager.swift
 ┣ 📂 Firebase        # Firebase関連ファイル
 ┃ ┣ 📄 AppDelegate.swift
 ┃ ┣ 📄 index.js (Cloud Functions)
 ┣ 📂 Components     # UIコンポーネント
 ┃ ┣ 📄 ItemRowView.swift
 ┃ ┣ 📄 GroupRowView.swift
 ┃ ┣ 📄 DetailRow.swift
 ┣ 📄 README.md
```

---

## 🔍 **Firestore データ構造**
### 🛒 **アイテム (`items` コレクション)**
```json
{
  "id": "アイテムID",
  "name": "アイテム名",
  "purchased": false,
  "order": 1,
  "location": "購入できる場所",
  "quantity": 1,
  "deadline": "2024-02-01",
  "memo": "追加情報",
  "registeredAt": "2024-01-30",
  "registrant": "ユーザーID",
  "buyer": "購入者ID",
  "purchasedAt": "2024-02-01",
  "groupId": "グループID"
}
```

### 👥 **グループ (`groups` コレクション)**
```json
{
  "id": "グループID",
  "name": "グループ名",
  "inviteCode": "ABC123",
  "members": ["ユーザーID1", "ユーザーID2"]
}
```

### 👤 **ユーザー (`users` コレクション)**
```json
{
  "uid": "ユーザーID",
  "firstName": "太郎",
  "lastName": "山田",
  "displayName": "やまだたろう",
  "email": "example@example.com",
  "birthdate": "2000-01-01",
  "fcmToken": "デバイスのトークン"
}
```

---

## 🚀 **セットアップ方法**
### 1️⃣ Firebaseプロジェクトの作成
- Firebase Console で新規プロジェクトを作成
- **Authentication**, **Firestore**, **Cloud Messaging** を有効化
- `GoogleService-Info.plist` を Xcode に追加

### 2️⃣ 必要なライブラリのインストール
```bash
pod install
```

### 3️⃣ Cloud Functions のデプロイ
```bash
cd firebase/functions
firebase deploy
```

---

## 📜 **主なファイルの説明**
### 🏠 **アプリのメインビュー**
📂 `ContentView.swift`
```swift
if session.isLoggedIn {
    TabView {
        NavigationView { HomeView() }
            .tabItem { Label("ホーム", systemImage: "house") }
        
        NavigationView { GroupListView() }
            .tabItem { Label("グループ", systemImage: "person.3") }
        
        NavigationView { SettingsView() }
            .tabItem { Label("設定", systemImage: "gear") }
    }
} else {
    LoginView(isLoggedIn: $session.isLoggedIn)
}
```

---

## 🔥 **通知の仕組み**
📂 `NotificationManager.swift`
```swift
func sendGroupNotification(for group: Group, title: String, body: String) {
    let db = Firestore.firestore()
    db.collection("groups").document(group.id).getDocument { document, error in
        if let document = document, let data = document.data(),
           let members = data["members"] as? [String] {
            
            db.collection("devices").whereField("userId", in: members).getDocuments { snapshot, error in
                let tokens = snapshot?.documents.flatMap { $0.data()["fcmTokens"] as? [String] ?? [] } ?? []
                for token in tokens {
                    self.sendNotification(to: token, title: title, body: body)
                }
            }
        }
    }
}
```

📂 `index.js` (Firebase Cloud Functions)
```js
exports.sendPushNotification = functions.https.onRequest(async (req, res) => {
  const {token, title, body} = req.body;
  const accessToken = await getAccessToken();
  const message = { message: { token, notification: { title, body } } };
  
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/sharedshoppinglist-feecd/messages:send`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(message),
  });

  res.status(200).send(await response.json());
});
```

---

## 🛠 **今後の改善点**
- **📶 オフライン対応**: Firestoreのキャッシュを活用したオフラインモード
- **📆 期限通知**: 買い物リストの期限が近づいたら通知
- **🌐 多言語対応**: ローカライズ機能を追加
- **🎨 UI改善**: SwiftUIのアニメーションやカスタムデザインの追加
