import SwiftUI

/// Smoothly animates between number values.
struct AnimatedCurrencyText: View {
    let cents: Int64
    let currency: String
    let font: Font
    let color: Color

    @State private var displayedCents: Double

    init(cents: Int64, currency: String = "USD", font: Font = .title.bold(), color: Color = .primary) {
        self.cents = cents
        self.currency = currency
        self.font = font
        self.color = color
        _displayedCents = State(initialValue: Double(cents))
    }

    var body: some View {
        let label = Text(CurrencyFormatter.format(cents: Int64(displayedCents), currency: currency))
            .font(font)
            .foregroundColor(color)

        if #available(iOS 17.0, *) {
            label
                .contentTransition(.numericText(value: displayedCents))
                .onChange(of: cents) { _, newValue in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        displayedCents = Double(newValue)
                    }
                }
        } else {
            label
                .onChange(of: cents) { newValue in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        displayedCents = Double(newValue)
                    }
                }
        }
    }
}

/// Animated number count-up for display values.
struct AnimatedNumberText: View {
    let value: Double
    let format: String
    let font: Font
    let color: Color

    init(value: Double, format: String = "%.0f", font: Font = .title2.bold(), color: Color = .primary) {
        self.value = value
        self.format = format
        self.font = font
        self.color = color
    }

    var body: some View {
        let label = Text(String(format: format, value))
            .font(font)
            .foregroundColor(color)

        if #available(iOS 17.0, *) {
            label
                .contentTransition(.numericText(value: value))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
        } else {
            label
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
        }
    }
}
