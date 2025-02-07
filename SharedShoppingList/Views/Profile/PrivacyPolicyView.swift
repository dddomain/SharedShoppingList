import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("""
                1. 収集する情報
                本アプリは、以下の情報を収集する場合があります：
                - ユーザーが提供する情報（氏名、メールアドレス、生年月日、表示名）
                - アカウント登録時の認証情報（Firebase Authentication により管理）
                - アプリ内での操作履歴（購入リストの作成、グループへの参加など）
                - デバイス情報（通知を送信するための FCM トークン）

                2. 情報の利用目的
                - アカウントの作成および管理
                - 買い物リストの管理と共有
                - グループメンバーとのコミュニケーション
                - プッシュ通知の送信
                - ユーザーサポート対応

                3. 情報の共有
                本アプリでは、以下の条件下で情報を共有する場合があります：
                - グループ機能において、メンバー同士が互いの表示名を閲覧可能
                - Firebase Firestore に保存された情報の適切なアクセス管理
                - 法的要請があった場合の情報提供
                """)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("プライバシーポリシー")
    }
}
