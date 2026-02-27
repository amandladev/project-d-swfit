import Foundation

struct Budget: Codable, Identifiable {
    let id: String
    let accountId: String
    let categoryId: String?
    let name: String
    let amount: Int64
    let period: String
    let startDate: String
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
}

struct BudgetProgress: Codable {
    let budgetId: String
    let budgetName: String
    let budgetAmount: Int64
    let spent: Int64
    let remaining: Int64
    let percentage: Double
    let period: String
    let startDate: String
    let endDate: String
    let categoryId: String?
    let categoryName: String?
}

// MARK: - Budget Period Enum

enum BudgetPeriod: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly:    return "Weekly"
        case .monthly:   return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly:    return "Yearly"
        }
    }
}
