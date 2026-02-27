import AppIntents
import WidgetKit

// MARK: - Quick Expense Intent (Background — no app launch)

/// Creates an expense transaction from the widget or Shortcuts without opening the app.
struct QuickExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Expense"
    static var description: IntentDescription = "Log an expense without opening the app"

    // Run entirely in the widget process — never open the app
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount (cents)")
    var amountCents: Int

    init() {
        self.amountCents = 0
    }

    init(amountCents: Int64) {
        self.amountCents = Int(amountCents)
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Initialize database
        WidgetDatabase.initialize()

        // Get saved user ID from shared App Group
        let userDefaults = UserDefaults(suiteName: "group.com.sergiofinance.FinanceApp")
        guard let userId = userDefaults?.string(forKey: "finance_current_user_id") else {
            return .result(value: "No user set up")
        }

        // Get accounts — use first account
        let accounts = try FinanceBridge.listAccounts(userId: userId)
        guard let account = accounts.first else {
            return .result(value: "No accounts found")
        }

        // Get categories — use first expense-like category or any category
        let categories = try FinanceBridge.listCategories(userId: userId)
        guard let category = categories.first else {
            return .result(value: "No categories found")
        }

        // Create the expense transaction
        let cents = Int64(amountCents)
        let dateStr = DateUtils.formatForAPI(Date())
        let amountFormatted = CurrencyFormatter.format(cents: cents, currency: account.currency)

        _ = try FinanceBridge.createTransaction(
            accountId: account.id,
            categoryId: category.id,
            amount: cents,
            transactionType: "expense",
            description: "Quick expense",
            date: dateStr
        )

        // Tell WidgetKit to refresh
        WidgetCenter.shared.reloadAllTimelines()

        return .result(value: "Logged \(amountFormatted)")
    }
}

// MARK: - Quick Income Intent (Background — no app launch)

/// Creates an income transaction from the widget or Shortcuts without opening the app.
struct QuickIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Income"
    static var description: IntentDescription = "Log income without opening the app"

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount (cents)")
    var amountCents: Int

    init() {
        self.amountCents = 0
    }

    init(amountCents: Int64) {
        self.amountCents = Int(amountCents)
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        WidgetDatabase.initialize()

        let userDefaults = UserDefaults(suiteName: "group.com.sergiofinance.FinanceApp")
        guard let userId = userDefaults?.string(forKey: "finance_current_user_id") else {
            return .result(value: "No user set up")
        }

        let accounts = try FinanceBridge.listAccounts(userId: userId)
        guard let account = accounts.first else {
            return .result(value: "No accounts found")
        }

        let categories = try FinanceBridge.listCategories(userId: userId)
        guard let category = categories.first else {
            return .result(value: "No categories found")
        }

        let cents = Int64(amountCents)
        let dateStr = DateUtils.formatForAPI(Date())
        let amountFormatted = CurrencyFormatter.format(cents: cents, currency: account.currency)

        _ = try FinanceBridge.createTransaction(
            accountId: account.id,
            categoryId: category.id,
            amount: cents,
            transactionType: "income",
            description: "Quick income",
            date: dateStr
        )

        WidgetCenter.shared.reloadAllTimelines()

        return .result(value: "Logged \(amountFormatted) income")
    }
}
