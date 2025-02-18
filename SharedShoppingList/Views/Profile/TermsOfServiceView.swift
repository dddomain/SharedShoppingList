import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("""
                1. 適用範囲
                本利用規約（以下「本規約」）は、本アプリのすべてのユーザーに適用されます。

                2. アカウントの管理
                - ユーザーは、自身のアカウント情報（メールアドレス、パスワード等）を適切に管理しなければなりません。
                - 他者に自身のアカウントを利用させることは禁止します。

                3. 禁止行為
                本アプリの利用において、以下の行為を禁止します：
                - 不正な情報の登録
                - 他のユーザーへの迷惑行為、嫌がらせ
                - アプリの運営を妨害する行為
                - 不適切なコンテンツの投稿
                - 法律や公序良俗に反する行為

                4. サービスの変更・終了
                - 運営者は、事前の通知なしにアプリの内容を変更、または提供を中止することがあります。
                - サービスの変更や終了により生じた損害について、運営者は一切の責任を負いません。
                """)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("利用規約")
    }
}
