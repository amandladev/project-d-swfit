import Foundation
import SwiftUI

struct Tag: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let color: String?
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - Helpers

extension Tag {
    /// Parses the hex color string into a SwiftUI Color. Falls back to accent color.
    var swiftUIColor: Color {
        guard let hex = color, !hex.isEmpty else { return AppTheme.accent }
        return Color(hex: hex)
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
