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

    /// The currency selected by the user for dashboard display — persisted.
    @Published var selectedCurrency: String {
        didSet { UserDefaults.standard.set(selectedCurrency, forKey: "dashboardCurrency") }
    }

    /// Total balance converted to selectedCurrency.
    @Published var convertedTotalBalance: Int64 = 0

    /// Income/expense totals already converted to selectedCurrency.
    @Published var convertedIncome: Int64 = 0
    @Published var convertedExpenses: Int64 = 0

    let userId: String

    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let month: String       // "Jan", "Feb", etc.
        let monthDate: Date
        let income: Int64
        let expenses: Int64
    }

    /// Unique currencies from the user's accounts, for the currency picker.
    var availableCurrencies: [String] {
        Array(Set(accounts.map { $0.currency })).sorted()
    }

    var totalIncome: Int64 { convertedIncome }
    var totalExpenses: Int64 { convertedExpenses }

    init(userId: String) {
        self.userId = userId
        self.selectedCurrency = UserDefaults.standard.string(forKey: "dashboardCurrency") ?? "USD"
    }

    func loadDashboard() {
        isLoading = true
        error = nil

        let userId = self.userId
        let targetCurrency = self.selectedCurrency

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
                var convertedTotal: Int64 = 0

                // Build a map of account currency for quick lookup
                let accountCurrencyMap = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0.currency) })

                for account in accounts {
                    if let bal = try? FinanceBridge.getBalance(accountId: account.id) {
                        balances[account.id] = bal.balance

                        // Convert balance to target currency
                        if account.currency == targetCurrency {
                            convertedTotal += bal.balance
                            print("🔵 \(account.name) [\(account.currency)] balance=\(bal.balance) → same currency, no conversion")
                        } else {
                            print("🟡 \(account.name) [\(account.currency)] balance=\(bal.balance) → converting to \(targetCurrency)...")
                            do {
                                let converted = try FinanceBridge.convertCurrency(
                                    amountCents: bal.balance, from: account.currency, to: targetCurrency
                                )
                                convertedTotal += converted.convertedAmountCents
                                print("🟢 Converted: \(bal.balance) \(account.currency) → \(converted.convertedAmountCents) \(targetCurrency) (rate: \(converted.rateUsed), source: \(converted.source))")
                            } catch {
                                convertedTotal += bal.balance
                                print("🔴 Conversion FAILED: \(error) — using raw value as fallback")
                            }
                        }
                    }
                    if let txns = try? FinanceBridge.listTransactions(accountId: account.id) {
                        allTransactions.append(contentsOf: txns)
                    }

                    // Use backend statistics for spending categories — convert to target currency
                    if let spending = try? FinanceBridge.getSpendingByCategory(
                        accountId: account.id, from: fromDate, to: toDate
                    ) {
                        for item in spending {
                            var convertedAmount = item.totalAmount
                            if account.currency != targetCurrency {
                                if let c = try? FinanceBridge.convertCurrency(
                                    amountCents: item.totalAmount, from: account.currency, to: targetCurrency
                                ) {
                                    convertedAmount = c.convertedAmountCents
                                }
                            }
                            aggregatedSpending[item.categoryName, default: 0] += convertedAmount
                        }
                    }

                    // Use backend income vs expenses — convert to target currency
                    do {
                        let ive = try FinanceBridge.getIncomeVsExpenses(
                            accountId: account.id, from: fromDate, to: toDate
                        )
                        if account.currency == targetCurrency {
                            totalIncome += ive.totalIncome
                            totalExpenses += ive.totalExpenses
                        } else {
                            if let ci = try? FinanceBridge.convertCurrency(
                                amountCents: ive.totalIncome, from: account.currency, to: targetCurrency
                            ) {
                                totalIncome += ci.convertedAmountCents
                            } else {
                                totalIncome += ive.totalIncome
                            }
                            if let ce = try? FinanceBridge.convertCurrency(
                                amountCents: ive.totalExpenses, from: account.currency, to: targetCurrency
                            ) {
                                totalExpenses += ce.convertedAmountCents
                            } else {
                                totalExpenses += ive.totalExpenses
                            }
                        }
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
                    for txn in currentMonthTxns {
                        let acctCurrency = accountCurrencyMap[txn.accountId] ?? targetCurrency
                        var amount = txn.amount
                        if acctCurrency != targetCurrency {
                            if let c = try? FinanceBridge.convertCurrency(
                                amountCents: txn.amount, from: acctCurrency, to: targetCurrency
                            ) {
                                amount = c.convertedAmountCents
                            }
                        }
                        if txn.transactionType == "income" {
                            totalIncome += amount
                        } else if txn.transactionType == "expense" {
                            totalExpenses += amount
                        }
                    }
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

                // Monthly data (last 6 months) — convert to target currency
                let monthlyData = Self.computeMonthlyData(
                    transactions: allTransactions,
                    months: 6,
                    targetCurrency: targetCurrency,
                    accountCurrencyMap: accountCurrencyMap
                )

                // Process any due recurring transactions
                let _ = try? FinanceBridge.processDueRecurringTransactions()

                let finalBalances = balances
                let finalConvertedTotal = convertedTotal

                await MainActor.run {
                    self.accounts = accounts
                    self.balances = finalBalances
                    self.convertedTotalBalance = finalConvertedTotal
                    self.convertedIncome = totalIncome
                    self.convertedExpenses = totalExpenses
                    self.recentTransactions = recent
                    self.categories = categories
                    self.spendingByCategory = spendingByCategory
                    self.incomeVsExpenses = incomeVsExpenses
                    self.monthlyData = monthlyData
                    self.isLoading = false

                    // Auto-detect currency on first launch if user hasn't set one
                    if UserDefaults.standard.string(forKey: "dashboardCurrency") == nil,
                       let first = accounts.first {
                        self.selectedCurrency = first.currency
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    /// Switch currency and reload dashboard with converted values.
    func switchCurrency(to currency: String) {
        selectedCurrency = currency
        loadDashboard()
    }

    // MARK: - Monthly Computation

    nonisolated private static func computeMonthlyData(
        transactions: [FinanceTransaction],
        months: Int,
        targetCurrency: String,
        accountCurrencyMap: [String: String]
    ) -> [MonthlyTotal] {
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

            var income: Int64 = 0
            var expenses: Int64 = 0
            for txn in monthTxns {
                let acctCurrency = accountCurrencyMap[txn.accountId] ?? targetCurrency
                var amount = txn.amount
                if acctCurrency != targetCurrency {
                    if let c = try? FinanceBridge.convertCurrency(
                        amountCents: txn.amount, from: acctCurrency, to: targetCurrency
                    ) {
                        amount = c.convertedAmountCents
                    }
                }
                if txn.transactionType == "income" {
                    income += amount
                } else if txn.transactionType == "expense" {
                    expenses += amount
                }
            }

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
