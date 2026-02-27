import WidgetKit
import SwiftUI

// MARK: - Shared DB Helper

enum WidgetDatabase {
    static func databasePath() -> String {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.sergiofinance.FinanceApp"
        ) {
            return groupURL.appendingPathComponent("finance.db").path
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("finance.db").path
    }

    static func initialize() {
        try? FinanceBridge.initDatabase(path: databasePath())
    }
}

// MARK: - Timeline Entry

struct BalanceEntry: TimelineEntry {
    let date: Date
    let balances: [(currency: String, amount: Int64)]
    let accounts: [Account]
    let hasData: Bool

    static var placeholder: BalanceEntry {
        BalanceEntry(
            date: .now,
            balances: [("USD", 250000)],
            accounts: [],
            hasData: true
        )
    }

    static var empty: BalanceEntry {
        BalanceEntry(date: .now, balances: [], accounts: [], hasData: false)
    }
}

// MARK: - Timeline Provider

struct BalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> BalanceEntry {
        WidgetDatabase.initialize()

        let userId = UserDefaults(suiteName: "group.com.sergiofinance.FinanceApp")?
            .string(forKey: "finance_current_user_id")

        guard let userId else { return .empty }

        guard let accounts = try? FinanceBridge.listAccounts(userId: userId) else {
            return .empty
        }

        var totals: [String: Int64] = [:]
        for account in accounts {
            if let bal = try? FinanceBridge.getBalance(accountId: account.id) {
                totals[account.currency, default: 0] += bal.balance
            }
        }

        let balances = totals
            .map { (currency: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

        return BalanceEntry(
            date: .now,
            balances: balances,
            accounts: accounts,
            hasData: !balances.isEmpty
        )
    }
}

// MARK: - Widget Definition

struct BalanceWidget: Widget {
    let kind = "FinanceBalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceProvider()) { entry in
            BalanceWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Finance Balance")
        .description("View your account balances and quickly add transactions.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View

struct BalanceWidgetView: View {
    let entry: BalanceEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                Text("Finance")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.hasData {
                ForEach(entry.balances, id: \.currency) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.currency)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(cents: item.amount, currency: item.currency))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("Open app to set up")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Updated \(entry.date, style: .time)")
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.quaternary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left: Balance section
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text("Finance")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if entry.hasData {
                    ForEach(entry.balances, id: \.currency) { item in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.currency)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.format(cents: item.amount, currency: item.currency))
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                        }
                    }
                } else {
                    Text("Open app to set up")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Spacer()

            // Right: Quick action buttons
            if entry.hasData {
                VStack(spacing: 8) {
                    Text("Quick Add")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    // Quick expense buttons with preset amounts
                    quickAmountGrid
                }
                .frame(width: 140)
            }
        }
    }

    // MARK: - Quick Amount Grid

    private var quickAmountGrid: some View {
        let presets: [(label: String, cents: Int64)] = [
            ("$5", 500),
            ("$10", 1000),
            ("$20", 2000),
            ("$50", 5000),
        ]

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6)
        ], spacing: 6) {
            ForEach(presets, id: \.cents) { preset in
                Button(intent: QuickExpenseIntent(amountCents: preset.cents)) {
                    Text(preset.label)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    BalanceWidget()
} timeline: {
    BalanceEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    BalanceWidget()
} timeline: {
    BalanceEntry.placeholder
}
