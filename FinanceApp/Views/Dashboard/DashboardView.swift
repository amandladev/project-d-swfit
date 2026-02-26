import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    let userId: String

    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: DashboardViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Card
                    balanceCard

                    // Income vs Expenses summary
                    incomeExpenseSummary

                    // Monthly Trend Chart
                    if !viewModel.monthlyData.isEmpty {
                        monthlyChart
                    }

                    // Spending by Category
                    if !viewModel.spendingByCategory.isEmpty {
                        spendingByCategorySection
                    }

                    // Recent Transactions
                    if !viewModel.recentTransactions.isEmpty {
                        recentTransactionsSection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Dashboard")
            .onAppear { viewModel.loadDashboard() }
            .refreshable { viewModel.loadDashboard() }
            .overlay {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 12) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Text(CurrencyFormatter.format(cents: viewModel.totalBalance))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                ForEach(viewModel.accounts.prefix(4)) { account in
                    VStack(spacing: 2) {
                        Text(account.name)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        Text(CurrencyFormatter.format(
                            cents: viewModel.balances[account.id] ?? 0,
                            currency: account.currency
                        ))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.68, blue: 0.38), Color(red: 0.1, green: 0.5, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .green.opacity(0.25), radius: 12, y: 6)
    }

    // MARK: - Income / Expense Summary

    private var incomeExpenseSummary: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Income",
                amount: viewModel.totalIncome,
                icon: "arrow.up.circle.fill",
                color: .green
            )
            SummaryCard(
                title: "Expenses",
                amount: viewModel.totalExpenses,
                icon: "arrow.down.circle.fill",
                color: .red
            )
        }
    }

    // MARK: - Monthly Chart

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Trend")
                .font(.headline)

            Chart(viewModel.monthlyData) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", CurrencyFormatter.toDecimal(cents: item.income))
                )
                .foregroundStyle(.green.opacity(0.8))
                .cornerRadius(4)
                .position(by: .value("Type", "Income"))

                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", CurrencyFormatter.toDecimal(cents: item.expenses))
                )
                .foregroundStyle(.red.opacity(0.8))
                .cornerRadius(4)
                .position(by: .value("Type", "Expenses"))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("$\(Int(v))")
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartLegend(position: .bottom, spacing: 16)
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                Label("Income", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Label("Expenses", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Spending by Category (Pie Chart)

    private var spendingByCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)

            Text("This month")
                .font(.caption)
                .foregroundColor(.secondary)

            SpendingPieChart(data: viewModel.spendingByCategory)
                .frame(height: 220)

            // Category breakdown list
            VStack(spacing: 8) {
                let totalSpending = viewModel.spendingByCategory.reduce(0) { $0 + $1.total }
                ForEach(viewModel.spendingByCategory.prefix(6), id: \.category.id) { item in
                    HStack(spacing: 10) {
                        Text(item.category.icon)
                            .font(.title3)
                        Text(item.category.name)
                            .font(.subheadline)
                        Spacer()
                        Text(CurrencyFormatter.format(cents: item.total))
                            .font(.subheadline.weight(.medium))
                        if totalSpending > 0 {
                            Text("\(Int(Double(item.total) / Double(totalSpending) * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.recentTransactions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.recentTransactions) { txn in
                    RecentTransactionRow(
                        transaction: txn,
                        categories: viewModel.categories
                    )

                    if txn.id != viewModel.recentTransactions.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let amount: Int64
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(CurrencyFormatter.format(cents: amount))
                .font(.title3.weight(.semibold))
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }
}

// MARK: - Recent Transaction Row

private struct RecentTransactionRow: View {
    let transaction: FinanceTransaction
    let categories: [FinanceCategory]

    private var category: FinanceCategory? {
        categories.first { $0.id == transaction.categoryId }
    }

    private var isExpense: Bool {
        transaction.transactionType == "expense"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(category?.icon ?? "💰")
                .font(.title2)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(DateUtils.relativeString(transaction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(CurrencyFormatter.format(
                cents: isExpense ? -transaction.amount : transaction.amount
            ))
            .font(.subheadline.weight(.semibold))
            .foregroundColor(isExpense ? .red : .green)
        }
        .padding(.vertical, 8)
    }
}
