import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var balances: [String: Int64] = [:]
    @Published var recentTransactions: [FinanceTransaction] = []
    @Published var categories: [FinanceCategory] = []
    @Published var spendingByCategory: [(category: String, total: Int64)] = []
    @Published var incomeVsExpenses: IncomeVsExpenses?
    @Published var monthlyData: [MonthlyTotal] = []
    @Published var isLoading = false
    @Published var error: String?

    let userId: String

    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let month: String       // "Jan", "Feb", etc.
        let monthDate: Date
        let income: Int64
        let expenses: Int64
    }

    var totalBalance: Int64 {
        balances.values.reduce(0, +)
    }

    /// The primary currency across accounts (most common, or first account's currency).
    var primaryCurrency: String {
        let currencies = accounts.map { $0.currency }
        // If all same, return that; otherwise pick most frequent
        let counts = Dictionary(currencies.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.max(by: { $0.value < $1.value })?.key ?? "USD"
    }

    /// Per-currency balance breakdown for multi-currency display.
    var balancesByCurrency: [(currency: String, total: Int64)] {
        var totals: [String: Int64] = [:]
        for account in accounts {
            let bal = balances[account.id] ?? 0
            totals[account.currency, default: 0] += bal
        }
        return totals.map { (currency: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    var totalIncome: Int64 {
        incomeVsExpenses?.totalIncome ?? recentTransactions
            .filter { $0.transactionType == "income" }
            .reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Int64 {
        incomeVsExpenses?.totalExpenses ?? recentTransactions
            .filter { $0.transactionType == "expense" }
            .reduce(0) { $0 + $1.amount }
    }

    init(userId: String) {
        self.userId = userId
    }

    func loadDashboard() {
        isLoading = true
        error = nil

        let userId = self.userId

        Task.detached {
            do {
                // Load accounts + balances
                let accounts = try FinanceBridge.listAccounts(userId: userId)
                var balances: [String: Int64] = [:]
                var allTransactions: [FinanceTransaction] = []

                // Date range: current month
                let calendar = Calendar.current
                let now = Date()
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let fromDate = DateUtils.formatForAPI(startOfMonth)
                let toDate = DateUtils.formatForAPI(now)

                var aggregatedSpending: [String: Int64] = [:]
                var totalIncome: Int64 = 0
                var totalExpenses: Int64 = 0

                for account in accounts {
                    if let bal = try? FinanceBridge.getBalance(accountId: account.id) {
                        balances[account.id] = bal.balance
                    }
                    if let txns = try? FinanceBridge.listTransactions(accountId: account.id) {
                        allTransactions.append(contentsOf: txns)
                    }

                    // Use backend statistics for spending categories
                    if let spending = try? FinanceBridge.getSpendingByCategory(
                        accountId: account.id, from: fromDate, to: toDate
                    ) {
                        for item in spending {
                            aggregatedSpending[item.categoryName, default: 0] += item.totalAmount
                        }
                    }

                    // Use backend income vs expenses
                    do {
                        let ive = try FinanceBridge.getIncomeVsExpenses(
                            accountId: account.id, from: fromDate, to: toDate
                        )
                        totalIncome += ive.totalIncome
                        totalExpenses += ive.totalExpenses
                    } catch {
                        print("⚠️ getIncomeVsExpenses failed for \(account.id): \(error)")
                    }
                }

                // Fallback: if backend returned 0 for both, compute from loaded transactions
                if totalIncome == 0 && totalExpenses == 0 && !allTransactions.isEmpty {
                    let comps = calendar.dateComponents([.year, .month], from: now)
                    let currentMonthTxns = allTransactions.filter { txn in
                        guard let date = DateUtils.parse(txn.date) else { return false }
                        let txnComps = calendar.dateComponents([.year, .month], from: date)
                        return txnComps.year == comps.year && txnComps.month == comps.month
                    }
                    totalIncome = currentMonthTxns
                        .filter { $0.transactionType == "income" }
                        .reduce(0) { $0 + $1.amount }
                    totalExpenses = currentMonthTxns
                        .filter { $0.transactionType == "expense" }
                        .reduce(0) { $0 + $1.amount }
                }

                // Build spending by category list from backend data
                let spendingByCategory = aggregatedSpending.map { (name, total) in
                    (category: name, total: total)
                }.sorted { $0.total > $1.total }

                let incomeVsExpenses = IncomeVsExpenses(
                    totalIncome: totalIncome,
                    totalExpenses: totalExpenses,
                    netBalance: totalIncome - totalExpenses,
                    periodFrom: fromDate,
                    periodTo: toDate
                )

                // Load categories
                let categories = try FinanceBridge.listCategories(userId: userId)

                // Sort all transactions by date descending
                let sorted = allTransactions.sorted { a, b in
                    (DateUtils.parse(a.date) ?? .distantPast) > (DateUtils.parse(b.date) ?? .distantPast)
                }

                // Recent transactions (last 10)
                let recent = Array(sorted.prefix(10))

                // Monthly data (last 6 months) – still client-side as it spans months
                let monthlyData = Self.computeMonthlyData(transactions: allTransactions, months: 6)

                // Process any due recurring transactions
                let _ = try? FinanceBridge.processDueRecurringTransactions()

                let finalBalances = balances

                await MainActor.run {
                    self.accounts = accounts
                    self.balances = finalBalances
                    self.recentTransactions = recent
                    self.categories = categories
                    self.spendingByCategory = spendingByCategory
                    self.incomeVsExpenses = incomeVsExpenses
                    self.monthlyData = monthlyData
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Monthly Computation

    nonisolated private static func computeMonthlyData(transactions: [FinanceTransaction], months: Int) -> [MonthlyTotal] {
        let calendar = Calendar.current
        let now = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        var result: [MonthlyTotal] = []

        for i in (0..<months).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: monthDate)

            let monthTxns = transactions.filter { txn in
                guard let date = DateUtils.parse(txn.date) else { return false }
                let txnComps = calendar.dateComponents([.year, .month], from: date)
                return txnComps.year == comps.year && txnComps.month == comps.month
            }

            let income = monthTxns.filter { $0.transactionType == "income" }.reduce(0) { $0 + $1.amount }
            let expenses = monthTxns.filter { $0.transactionType == "expense" }.reduce(0) { $0 + $1.amount }

            result.append(MonthlyTotal(
                month: monthFormatter.string(from: monthDate),
                monthDate: monthDate,
                income: income,
                expenses: expenses
            ))
        }

        return result
    }
}
