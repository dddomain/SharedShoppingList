# 買い物リスト共有アプリ

## 概要
このアプリはグループで買い物リストを共有・管理するiOSアプリです。ユーザーはグループを作成し、アイテムを登録・管理することができます。また、招待コードを使ってグループに参加し、複数人でリアルタイムにリストを更新することが可能です。Firebaseを活用してデータの管理や認証を行います。

## 主な機能
- **ユーザー認証**
  - メールアドレスとパスワードでログイン / 新規登録
  - Firestoreにユーザー情報を保存
- **グループ管理**
  - グループの作成、削除、メンバー招待
  - 招待コードを使ったグループ参加
- **アイテム管理**
  - グループごとにアイテムの登録・編集・削除
  - アイテムの購入状態の管理
- **ユーザー情報管理**
  - プロフィールの表示と管理
- **Firebase連携**
  - Firestoreでデータ管理
  - Firebase Authenticationでユーザー認証
  - FCM（Firebase Cloud Messaging）でプッシュ通知対応（予定）

## 使用技術
- **SwiftUI** - ユーザーインターフェース構築
- **Firebase**
  - Firestore - データベース
  - Firebase Authentication - ユーザー認証
  - Firebase Messaging - プッシュ通知
- **MVVMアーキテクチャ** - データとUIを分離

## ディレクトリ構成
```
.
├── Models
│   ├── Group.swift
│   ├── Item.swift
│   ├── SessionManager.swift
│   └── UserInfoManager.swift
│
├── Views
│   ├── ContentView.swift
│   ├── HomeView.swift
│   ├── GroupListView.swift
│   ├── GroupDetailView.swift
│   ├── ItemListView.swift
│   ├── ItemDetailView.swift
│   ├── SettingsView.swift
│   ├── ProfileView.swift
│   ├── LoginView.swift
│   └── SignUpView.swift
│
└── Components
    ├── GroupRowView.swift
    └── ItemRowView.swift
```

## セットアップ方法
1. Firebaseプロジェクトを作成し、アプリに必要なAPIキーと設定ファイル（`GoogleService-Info.plist`）をXcodeプロジェクトに追加。
2. Firebase Authenticationを有効化し、「メール/パスワード認証」を設定。
3. Firestoreデータベースを作成し、セキュリティルールを適切に設定。
4. FCM（Firebase Cloud Messaging）を使用する場合は、通知の設定も行います。
5. `pod install`でFirebaseの依存関係をインストール。
6. Xcodeでプロジェクトをビルドして実行。

## 使用方法
1. アプリを起動し、新規登録またはログイン。
2. グループを作成し、買い物リストを追加。
3. 招待コードを共有して他のメンバーをグループに招待。
4. リスト内のアイテムをタップして購入済みにする。

## 今後の機能追加予定
- プッシュ通知の実装（購入済みアイテムの通知）
- アイテム画像のアップロード機能
- グループチャット機能

---

### Firebaseセットアップ参考リンク
- [Firebase公式ドキュメント](https://firebase.google.com/docs/ios/setup?hl=ja)
- [Firestoreのルール設定ガイド](https://firebase.google.com/docs/firestore/security/get-started)

