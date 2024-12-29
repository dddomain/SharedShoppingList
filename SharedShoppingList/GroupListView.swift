
import SwiftUI

struct GroupListView: View {
    @State private var groups: [Group] = []

    var body: some View {
        List(groups) { group in
            NavigationLink(destination: ItemListView(group: group)) {
                Text(group.name)
            }
        }
        .navigationTitle("グループ")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // グループ新規作成ロジック
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .previewLayout(.device)
    }
}
