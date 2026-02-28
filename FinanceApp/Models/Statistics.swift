import Foundation

/// Response from get_spending_by_category FFI call
struct CategorySpending: Codable, Identifiable {
    let categoryId: String
    let categoryName: String
    let totalAmount: Int64

    var id: String { categoryId }
}

/// Response from get_income_vs_expenses FFI call
struct IncomeVsExpenses: Codable {
    let totalIncome: Int64
    let totalExpenses: Int64
    let netBalance: Int64
    let periodFrom: String
    let periodTo: String
}

// MARK: - Currency Conversion Models

/// Response from convert_currency FFI call
struct CurrencyConversion: Codable {
    let fromCurrency: String
    let toCurrency: String
    let originalAmount: Int64
    let convertedAmount: Int64
    let rate: Int64
    let rateSource: String
    let rateFetchedAt: String?

    // Convenience accessors matching old API names used in codebase
    var originalAmountCents: Int64 { originalAmount }
    var convertedAmountCents: Int64 { convertedAmount }
    var rateUsed: Double { Double(rate) / 1_000_000.0 }
    var source: String { rateSource }
}

/// Response from get_rate_freshness FFI call
struct RateFreshness: Codable {
    let source: String
    let ageSeconds: Int64?
    let fetchedAt: String?
}

/// Response from list_exchange_rates FFI call
struct ExchangeRate: Codable, Identifiable {
    let fromCurrency: String
    let toCurrency: String
    let rate: Int64
    let source: String
    let fetchedAt: String?

    var id: String { "\(fromCurrency)_\(toCurrency)" }

    /// Actual decimal rate (backend stores as micro-rate × 1,000,000)
    var decimalRate: Double { Double(rate) / 1_000_000.0 }
}
