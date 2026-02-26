import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var balances: [String: Int64] = [:]
    @Published var recentTransactions: [FinanceTransaction] = []
    @Published var categories: [FinanceCategory] = []
    @Published var spendingByCategory: [(category: FinanceCategory, total: Int64)] = []
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

    var totalIncome: Int64 {
        recentTransactions
            .filter { $0.transactionType == "income" }
            .reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Int64 {
        recentTransactions
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

                for account in accounts {
                    if let bal = try? FinanceBridge.getBalance(accountId: account.id) {
                        balances[account.id] = bal.balance
                    }
                    if let txns = try? FinanceBridge.listTransactions(accountId: account.id) {
                        allTransactions.append(contentsOf: txns)
                    }
                }

                // Load categories
                let categories = try FinanceBridge.listCategories(userId: userId)

                // Sort all transactions by date descending
                let sorted = allTransactions.sorted { a, b in
                    (DateUtils.parse(a.date) ?? .distantPast) > (DateUtils.parse(b.date) ?? .distantPast)
                }

                // Recent transactions (last 10)
                let recent = Array(sorted.prefix(10))

                // Spending by category (expenses only, current month)
                let now = Date()
                let calendar = Calendar.current
                let thisMonthTxns = allTransactions.filter { txn in
                    guard txn.transactionType == "expense",
                          let date = DateUtils.parse(txn.date) else { return false }
                    return calendar.isDate(date, equalTo: now, toGranularity: .month)
                }

                var categoryTotals: [String: Int64] = [:]
                for txn in thisMonthTxns {
                    categoryTotals[txn.categoryId, default: 0] += txn.amount
                }

                let spendingByCategory = categoryTotals.compactMap { (catId, total) -> (category: FinanceCategory, total: Int64)? in
                    guard let cat = categories.first(where: { $0.id == catId }) else { return nil }
                    return (category: cat, total: total)
                }.sorted { $0.total > $1.total }

                // Monthly data (last 6 months)
                let monthlyData = Self.computeMonthlyData(transactions: allTransactions, months: 6)

                await MainActor.run {
                    self.accounts = accounts
                    self.balances = balances
                    self.recentTransactions = recent
                    self.categories = categories
                    self.spendingByCategory = spendingByCategory
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
