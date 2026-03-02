import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("balanceHidden") private var balanceHidden = false
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
                        .transition(.move(edge: .top).combined(with: .opacity))

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
            .background(AppTheme.surfaceBackground.ignoresSafeArea())
            .navigationTitle(L10n.tr("dashboard.title"))
            .onAppear { viewModel.loadDashboard() }
            .refreshable { viewModel.loadDashboard() }
            .overlay {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    BrandedLoadingView()
                }
            }
        }
    }

    // MARK: - Balance Card

    @State private var showCurrencyPicker = false

    private var balanceCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text(L10n.tr("dashboard.totalBalance"))
                    .font(AppTheme.subheadlineFont)
                    .foregroundColor(.white.opacity(0.75))
                Spacer()

                // Currency picker button
                if viewModel.availableCurrencies.count > 1 {
                    Button {
                        showCurrencyPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedCurrency)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        balanceHidden.toggle()
                    }
                } label: {
                    Image(systemName: balanceHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Single converted balance
            AnimatedCurrencyText(
                cents: viewModel.convertedTotalBalance,
                currency: viewModel.selectedCurrency,
                font: AppTheme.displayFont(40),
                color: .white
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(balanceHidden ? 0 : 1)
            .blur(radius: balanceHidden ? 12 : 0)
            .overlay(alignment: .leading) {
                Text("••••••")
                    .font(AppTheme.displayFont(40))
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(balanceHidden ? 1 : 0)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: balanceHidden)

            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: 16) {
                ForEach(viewModel.accounts.prefix(4)) { account in
                    VStack(spacing: 3) {
                        Text(account.name)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                        Text(CurrencyFormatter.format(
                            cents: viewModel.balances[account.id] ?? 0,
                            currency: account.currency
                        ))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(balanceHidden ? 0 : 1)
                        .blur(radius: balanceHidden ? 8 : 0)
                        .overlay {
                            Text("••••")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .opacity(balanceHidden ? 1 : 0)
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: balanceHidden)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            ZStack {
                AppTheme.balanceGradient
                // Decorative circles
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 180, height: 180)
                    .offset(x: 100, y: -60)
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 120, height: 120)
                    .offset(x: -80, y: 50)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(
            color: AppTheme.accent.opacity(colorScheme == .dark ? 0.3 : 0.25),
            radius: 16, y: 8
        )
        .confirmationDialog(L10n.tr("dashboard.displayCurrency"), isPresented: $showCurrencyPicker, titleVisibility: .visible) {
            ForEach(viewModel.availableCurrencies, id: \.self) { currency in
                Button(currency) {
                    viewModel.switchCurrency(to: currency)
                }
            }
        }
    }

    // MARK: - Income / Expense Summary

    private var incomeExpenseSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L10n.tr("dashboard.thisMonth"))
                    .font(AppTheme.captionFont)
                    .foregroundColor(.secondary)
                Spacer()
            }
            HStack(spacing: 12) {
                SummaryCard(
                    title: L10n.tr("dashboard.income"),
                    amount: viewModel.totalIncome,
                    currency: viewModel.selectedCurrency,
                    icon: "arrow.up.circle.fill",
                    gradient: AppTheme.incomeGradient,
                    color: AppTheme.income
                )
                SummaryCard(
                    title: L10n.tr("dashboard.expenses"),
                    amount: viewModel.totalExpenses,
                    currency: viewModel.selectedCurrency,
                    icon: "arrow.down.circle.fill",
                    gradient: AppTheme.expenseGradient,
                    color: AppTheme.expense
                )
            }
        }
    }

    // MARK: - Monthly Chart

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("dashboard.monthlyTrend"))
                .font(AppTheme.headlineFont)

            Chart(viewModel.monthlyData) { item in
                BarMark(
                    x: .value(L10n.tr("chart.month"), item.month),
                    y: .value(L10n.tr("chart.amount"), CurrencyFormatter.toDecimal(cents: item.income))
                )
                .foregroundStyle(AppTheme.income.opacity(0.85))
                .cornerRadius(6)
                .position(by: .value("Type", L10n.tr("chart.income")))

                BarMark(
                    x: .value(L10n.tr("chart.month"), item.month),
                    y: .value(L10n.tr("chart.amount"), CurrencyFormatter.toDecimal(cents: item.expenses))
                )
                .foregroundStyle(AppTheme.expense.opacity(0.85))
                .cornerRadius(6)
                .position(by: .value("Type", L10n.tr("chart.expenses")))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("$\(Int(v))")
                                .font(.system(size: 10, design: .rounded))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                }
            }
            .chartLegend(position: .bottom, spacing: 16)
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                Label(L10n.tr("chart.income"), systemImage: "circle.fill")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.income)
                Label(L10n.tr("chart.expenses"), systemImage: "circle.fill")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.expense)
            }
        }
        .themedCard()
    }

    // MARK: - Spending by Category (Pie Chart)

    private var spendingByCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("dashboard.spendingByCategory"))
                .font(AppTheme.headlineFont)

            Text(L10n.tr("dashboard.thisMonthLower"))
                .font(AppTheme.captionFont)
                .foregroundColor(.secondary)

            SpendingPieChart(data: viewModel.spendingByCategory)
                .frame(height: 220)

            // Category breakdown list
            VStack(spacing: 10) {
                let totalSpending = viewModel.spendingByCategory.reduce(0) { $0 + $1.total }
                ForEach(viewModel.spendingByCategory.prefix(6), id: \.category) { item in
                    HStack(spacing: 10) {
                        Text(item.category)
                            .font(AppTheme.subheadlineFont)
                        Spacer()
                        Text(CurrencyFormatter.format(cents: item.total))
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                        if totalSpending > 0 {
                            Text("\(Int(Double(item.total) / Double(totalSpending) * 100))%")
                                .font(AppTheme.captionFont)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                                .frame(width: 42, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .themedCard()
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.tr("dashboard.recentTransactions"))
                    .font(AppTheme.headlineFont)
                Spacer()
                Text("\(viewModel.recentTransactions.count)")
                    .font(AppTheme.captionFont)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(8)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.recentTransactions) { txn in
                    RecentTransactionRow(
                        transaction: txn,
                        categories: viewModel.categories,
                        currency: viewModel.accounts.first { $0.id == txn.accountId }?.currency ?? viewModel.selectedCurrency
                    )

                    if txn.id != viewModel.recentTransactions.last?.id {
                        Divider()
                            .padding(.leading, 52)
                            .opacity(0.5)
                    }
                }
            }
        }
        .themedCard()
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let amount: Int64
    var currency: String = "USD"
    let icon: String
    let gradient: LinearGradient
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(6)
                    .background(color.opacity(0.3))
                    .clipShape(Circle())
                Spacer()
            }
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundColor(.white.opacity(0.8))
            AnimatedCurrencyText(
                cents: amount,
                currency: currency,
                font: AppTheme.displayFont(18, weight: .semibold),
                color: .white
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: color.opacity(colorScheme == .dark ? 0.3 : 0.2),
            radius: 8, y: 4
        )
    }
}

// MARK: - Recent Transaction Row

private struct RecentTransactionRow: View {
    let transaction: FinanceTransaction
    let categories: [FinanceCategory]
    var currency: String = "USD"

    private var category: FinanceCategory? {
        categories.first { $0.id == transaction.categoryId }
    }

    private var isExpense: Bool {
        transaction.transactionType == "expense"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((isExpense ? AppTheme.expense : AppTheme.income).opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(category?.icon ?? "💰")
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.description)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .lineLimit(1)
                Text(DateUtils.relativeString(transaction.date))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(CurrencyFormatter.format(
                cents: isExpense ? -transaction.amount : transaction.amount,
                currency: currency
            ))
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundColor(isExpense ? AppTheme.expense : AppTheme.income)
        }
        .padding(.vertical, 8)
    }
}
