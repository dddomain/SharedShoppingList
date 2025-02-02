import SwiftUI

class ColorManager {
    static let shared = ColorManager()
    
    private init() {}

    static func getColor(from name: String) -> Color {
        switch name {
        case "red": return .red
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue  // デフォルトをblueに
        }
    }
}
