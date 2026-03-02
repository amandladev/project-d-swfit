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
        case .daily:      return L10n.tr("frequency.daily")
        case .weekly:     return L10n.tr("frequency.weekly")
        case .biWeekly:   return L10n.tr("frequency.biWeekly")
        case .monthly:    return L10n.tr("frequency.monthly")
        case .quarterly:  return L10n.tr("frequency.quarterly")
        case .yearly:     return L10n.tr("frequency.yearly")
        }
    }
}
