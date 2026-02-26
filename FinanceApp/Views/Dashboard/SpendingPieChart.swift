import SwiftUI
import Charts

/// Pie chart showing spending distribution by category.
struct SpendingPieChart: View {
    let data: [(category: FinanceCategory, total: Int64)]

    private let colors: [Color] = [
        .blue, .orange, .green, .red, .purple,
        .pink, .yellow, .cyan, .mint, .indigo,
        .teal, .brown
    ]

    var body: some View {
        if #available(iOS 17.0, *) {
            sectorChart
        } else {
            // Fallback for iOS 16 — use bar chart as approximation
            barFallback
        }
    }

    // MARK: - iOS 17+ Sector (Pie) Chart

    @available(iOS 17.0, *)
    private var sectorChart: some View {
        Chart(Array(data.prefix(8).enumerated()), id: \.element.category.id) { index, item in
            SectorMark(
                angle: .value("Amount", item.total),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(colors[index % colors.count])
            .cornerRadius(4)
            .annotation(position: .overlay) {
                if shouldShowLabel(item: item) {
                    Text(item.category.icon)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - iOS 16 Fallback

    private var barFallback: some View {
        Chart(Array(data.prefix(8).enumerated()), id: \.element.category.id) { index, item in
            BarMark(
                x: .value("Amount", CurrencyFormatter.toDecimal(cents: item.total)),
                y: .value("Category", item.category.name)
            )
            .foregroundStyle(colors[index % colors.count])
            .cornerRadius(6)
            .annotation(position: .trailing) {
                Text(CurrencyFormatter.format(cents: item.total))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .chartXAxis(.hidden)
    }

    // MARK: - Helpers

    private func shouldShowLabel(item: (category: FinanceCategory, total: Int64)) -> Bool {
        let total = data.reduce(0) { $0 + $1.total }
        guard total > 0 else { return false }
        return Double(item.total) / Double(total) > 0.08  // Only show if > 8%
    }
}
