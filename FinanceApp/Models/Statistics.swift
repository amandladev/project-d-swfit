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
