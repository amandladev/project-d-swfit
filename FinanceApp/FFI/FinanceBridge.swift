import Foundation

// MARK: - FFI Error Types

enum FFIError: LocalizedError {
    case nullPointer
    case invalidUTF8
    case decodingFailed(String)
    case backendError(code: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .nullPointer:
            return "FFI returned null pointer"
        case .invalidUTF8:
            return "FFI returned invalid UTF-8 string"
        case .decodingFailed(let detail):
            return "Failed to decode FFI response: \(detail)"
        case .backendError(_, let message):
            return message
        }
    }
}

// MARK: - Finance Bridge

/// Swift wrapper around the Rust FFI C functions.
/// All C functions return JSON strings that are decoded into Swift types.
final class FinanceBridge {

    // Shared decoder configured for Rust/serde snake_case JSON keys
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Private Helpers

    /// Calls an FFI function, decodes the JSON response, and returns the data payload.
    private static func call<T: Decodable>(_ ptr: UnsafeMutablePointer<CChar>?) throws -> T {
        guard let ptr = ptr else {
            throw FFIError.nullPointer
        }
        defer { free_string(ptr) }

        let jsonString = String(cString: ptr)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw FFIError.invalidUTF8
        }

        let response: FFIResponse<T>
        do {
            response = try decoder.decode(FFIResponse<T>.self, from: jsonData)
        } catch {
            throw FFIError.decodingFailed(error.localizedDescription)
        }

        guard response.success else {
            throw FFIError.backendError(code: response.code, message: response.message)
        }

        guard let data = response.data else {
            throw FFIError.decodingFailed("Response succeeded but data is nil")
        }

        return data
    }

    /// Calls an FFI function that returns no meaningful data payload (e.g. delete, init).
    private static func callVoid(_ ptr: UnsafeMutablePointer<CChar>?) throws {
        guard let ptr = ptr else {
            throw FFIError.nullPointer
        }
        defer { free_string(ptr) }

        let jsonString = String(cString: ptr)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw FFIError.invalidUTF8
        }

        let response: FFIResponse<EmptyData>
        do {
            response = try decoder.decode(FFIResponse<EmptyData>.self, from: jsonData)
        } catch {
            throw FFIError.decodingFailed(error.localizedDescription)
        }

        guard response.success else {
            throw FFIError.backendError(code: response.code, message: response.message)
        }
    }

    // MARK: - Database

    /// Initialize the SQLite database at the given file path.
    static func initDatabase(path: String) throws {
        try callVoid(init_database(path))
    }

    // MARK: - Users

    static func createUser(name: String, email: String) throws -> User {
        try call(create_user(name, email))
    }

    static func getUser(userId: String) throws -> User {
        try call(get_user(userId))
    }

    // MARK: - Accounts

    static func createAccount(userId: String, name: String, currency: String) throws -> Account {
        try call(create_account(userId, name, currency))
    }

    static func listAccounts(userId: String) throws -> [Account] {
        try call(list_accounts(userId))
    }

    static func deleteAccount(accountId: String) throws {
        try callVoid(delete_account(accountId))
    }

    // MARK: - Categories

    static func createCategory(userId: String, name: String, icon: String) throws -> FinanceCategory {
        try call(create_category(userId, name, icon))
    }

    static func listCategories(userId: String) throws -> [FinanceCategory] {
        try call(list_categories(userId))
    }

    static func deleteCategory(categoryId: String) throws {
        try callVoid(delete_category(categoryId))
    }

    // MARK: - Transactions

    static func createTransaction(
        accountId: String,
        categoryId: String,
        amount: Int64,
        transactionType: String,
        description: String,
        date: String
    ) throws -> FinanceTransaction {
        try call(
            create_transaction(accountId, categoryId, amount, transactionType, description, date)
        )
    }

    static func editTransaction(
        transactionId: String,
        amount: Int64,
        transactionType: String,
        description: String,
        categoryId: String,
        date: String
    ) throws -> FinanceTransaction {
        try call(
            edit_transaction(transactionId, amount, transactionType, description, categoryId, date)
        )
    }

    static func deleteTransaction(transactionId: String) throws {
        try callVoid(delete_transaction(transactionId))
    }

    static func listTransactions(accountId: String) throws -> [FinanceTransaction] {
        try call(list_transactions(accountId))
    }

    static func listTransactionsByDateRange(
        accountId: String,
        from: String,
        to: String
    ) throws -> [FinanceTransaction] {
        try call(list_transactions_by_date_range(accountId, from, to))
    }

    // MARK: - Balance

    static func getBalance(accountId: String) throws -> Balance {
        try call(get_balance(accountId))
    }

    // MARK: - Statistics

    static func getSpendingByCategory(accountId: String, from: String, to: String) throws -> [CategorySpending] {
        try call(get_spending_by_category(accountId, from, to))
    }

    static func getIncomeVsExpenses(accountId: String, from: String, to: String) throws -> IncomeVsExpenses {
        try call(get_income_vs_expenses(accountId, from, to))
    }

    // MARK: - Recurring Transactions

    static func createRecurringTransaction(
        accountId: String,
        categoryId: String,
        amount: Int64,
        transactionType: String,
        description: String,
        frequency: String,
        startDate: String,
        endDate: String?
    ) throws -> RecurringTransaction {
        try call(
            create_recurring_transaction(
                accountId,
                categoryId,
                amount,
                transactionType,
                description,
                frequency,
                startDate,
                endDate
            )
        )
    }

    static func listRecurringTransactions(accountId: String) throws -> [RecurringTransaction] {
        try call(list_recurring_transactions(accountId))
    }

    static func deleteRecurringTransaction(id: String) throws {
        try callVoid(delete_recurring_transaction(id))
    }

    static func processDueRecurringTransactions() throws -> [FinanceTransaction] {
        try call(process_due_recurring_transactions())
    }

    // MARK: - Budgets

    static func createBudget(
        accountId: String,
        categoryId: String?,
        name: String,
        amount: Int64,
        period: String,
        startDate: String
    ) throws -> Budget {
        try call(
            create_budget(accountId, categoryId, name, amount, period, startDate)
        )
    }

    static func listBudgets(accountId: String) throws -> [Budget] {
        try call(list_budgets(accountId))
    }

    static func deleteBudget(id: String) throws {
        try callVoid(delete_budget(id))
    }

    static func getBudgetProgress(budgetId: String) throws -> BudgetProgress {
        try call(get_budget_progress(budgetId))
    }

    // MARK: - Sync

    static func getPendingSync() throws -> [FinanceTransaction] {
        try call(get_pending_sync())
    }

    // MARK: - Category Seeding

    /// Seeds default categories from the backend. Idempotent.
    static func seedDefaultCategories(userId: String) throws -> [FinanceCategory] {
        try call(seed_default_categories(userId))
    }

    // MARK: - Exchange Rates

    /// Seed bundled default exchange rates. Call once after init_database.
    static func seedExchangeRates() throws {
        try callVoid(seed_exchange_rates())
    }

    /// Update cached exchange rates from API data.
    /// JSON format: `[{"from":"USD","to":"EUR","rate":0.92}, ...]`
    static func updateExchangeRates(ratesJson: String) throws {
        try callVoid(update_exchange_rates(ratesJson))
    }

    /// Set a manual exchange rate (user override — highest priority).
    static func setManualExchangeRate(from: String, to: String, rate: Double) throws {
        try callVoid(set_manual_exchange_rate(from, to, rate))
    }

    /// Convert cents between currencies using 3-tier resolution.
    static func convertCurrency(amountCents: Int64, from: String, to: String) throws -> CurrencyConversion {
        try call(convert_currency(amountCents, from, to))
    }

    /// Get rate freshness info for a currency pair.
    static func getRateFreshness(from: String, to: String) throws -> RateFreshness {
        try call(get_rate_freshness(from, to))
    }

    /// List all exchange rates from a base currency.
    static func listExchangeRates(from: String) throws -> [ExchangeRate] {
        try call(list_exchange_rates(from))
    }

    // MARK: - Search

    /// Search transactions with flexible filtering. Only account_id is required.
    static func searchTransactions(filterJson: String) throws -> [FinanceTransaction] {
        try call(search_transactions(filterJson))
    }

    // MARK: - Tags

    /// Create a tag with an optional hex color.
    static func createTag(userId: String, name: String, color: String?) throws -> Tag {
        try call(create_tag(userId, name, color))
    }

    /// List all tags for a user (alphabetical).
    static func listTags(userId: String) throws -> [Tag] {
        try call(list_tags(userId))
    }

    /// Update a tag's name and/or color via JSON.
    static func updateTag(tagId: String, updateJson: String) throws -> Tag {
        try call(update_tag(tagId, updateJson))
    }

    /// Delete a tag and all its transaction associations.
    static func deleteTag(tagId: String) throws {
        try callVoid(delete_tag(tagId))
    }

    /// Add a tag to a transaction (idempotent).
    static func addTagToTransaction(transactionId: String, tagId: String) throws {
        try callVoid(add_tag_to_transaction(transactionId, tagId))
    }

    /// Remove a tag from a transaction.
    static func removeTagFromTransaction(transactionId: String, tagId: String) throws {
        try callVoid(remove_tag_from_transaction(transactionId, tagId))
    }

    /// Get all tags on a transaction.
    static func getTransactionTags(transactionId: String) throws -> [Tag] {
        try call(get_transaction_tags(transactionId))
    }

    /// Get all transaction IDs that have a given tag.
    static func getTransactionsByTag(tagId: String) throws -> [String] {
        try call(get_transactions_by_tag(tagId))
    }

    // MARK: - Budget Progress (Batch)

    /// Get progress for all budgets in an account at once.
    static func getAllBudgetsProgress(accountId: String) throws -> [BudgetProgress] {
        try call(get_all_budgets_progress(accountId))
    }
}
