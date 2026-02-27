import SwiftUI

// MARK: - App Theme

/// Centralized color and styling theme supporting dark mode.
struct AppTheme {

    // MARK: - Brand Colors

    static let primary = Color("AccentColor")
    static let accent = Color(red: 0.18, green: 0.72, blue: 0.42)       // Emerald green
    static let accentDark = Color(red: 0.12, green: 0.52, blue: 0.36)

    // MARK: - Semantic Colors

    static let income = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let expense = Color(red: 0.95, green: 0.3, blue: 0.35)
    static let transfer = Color(red: 0.35, green: 0.55, blue: 0.95)

    // MARK: - Surface Colors (adapt to dark mode)

    static var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }

    static var surfaceBackground: Color {
        Color(.systemGroupedBackground)
    }

    static var elevatedSurface: Color {
        Color(.tertiarySystemGroupedBackground)
    }

    // MARK: - Gradient Palettes

    static let balanceGradient = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.62, blue: 0.45),
            Color(red: 0.06, green: 0.42, blue: 0.52),
            Color(red: 0.08, green: 0.30, blue: 0.48)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let incomeGradient = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.68, blue: 0.38),
            Color(red: 0.20, green: 0.78, blue: 0.45)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let expenseGradient = LinearGradient(
        colors: [
            Color(red: 0.90, green: 0.25, blue: 0.30),
            Color(red: 0.95, green: 0.40, blue: 0.40)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Card Style

    static let cardCornerRadius: CGFloat = 20
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 6

    // MARK: - Fonts

    static func displayFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let headlineFont = Font.system(.headline, design: .rounded)
    static let subheadlineFont = Font.system(.subheadline, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)

    // MARK: - Icon Background

    static func iconCircle(color: Color, size: CGFloat = 42) -> some View {
        Circle()
            .fill(color.opacity(0.15))
            .frame(width: size, height: size)
    }
}

// MARK: - Card Modifier

struct ThemedCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cardCornerRadius)
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.3)
                    : Color.black.opacity(0.06),
                radius: AppTheme.cardShadowRadius,
                y: AppTheme.cardShadowY
            )
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }
}

// MARK: - Glassmorphism Modifier (for overlays)

struct GlassModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(14)
    }
}

extension View {
    func glassStyle() -> some View {
        modifier(GlassModifier())
    }
}
