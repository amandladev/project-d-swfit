import Foundation

struct RecurringTransaction: Codable, Identifiable {
    let id: String
    let accountId: String
    let categoryId: String
    let amount: Int64
    let transactionType: String
    let description: String
    let frequency: String
    let startDate: String
    let endDate: String?
    let nextDueDate: String?
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
}

// MARK: - Frequency Enum

enum RecurrenceFrequency: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case biWeekly = "bi-weekly"
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:      return "Daily"
        case .weekly:     return "Weekly"
        case .biWeekly:   return "Bi-Weekly"
        case .monthly:    return "Monthly"
        case .quarterly:  return "Quarterly"
        case .yearly:     return "Yearly"
        }
    }
}
