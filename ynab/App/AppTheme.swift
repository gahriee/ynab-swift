import SwiftUI

enum AppColors {
    // Brand (YNAB Blue/Teal vibe)
    static let primary     = Color(hex: "0284C7")  // Sky 600
    
    // Semantic
    static let income      = Color(hex: "10B981")  // Emerald 500
    static let expense     = Color(hex: "EF4444")  // Red 500
    static let warning     = Color(hex: "F59E0B")  // Amber 500
}

// Hex color initializer — Swift 5.9 compatible
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255
        g = Double((int >>  8) & 0xFF) / 255
        b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
