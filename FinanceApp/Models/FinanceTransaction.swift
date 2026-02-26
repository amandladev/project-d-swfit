import Foundation

// Named FinanceTransaction to avoid conflict with SwiftUI.Transaction
struct FinanceTransaction: Codable, Identifiable {
    let id: String
    let accountId: String
    let categoryId: String
    let amount: Int64
    let transactionType: String
    let description: String
    let date: String
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    let syncStatus: String?
}

// MARK: - Transaction Type Enum

enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
    case transfer

    var displayName: String {
        switch self {
        case .expense:  return "Expense"
        case .income:   return "Income"
        case .transfer: return "Transfer"
        }
    }

    var icon: String {
        switch self {
        case .expense:  return "arrow.down.circle.fill"
        case .income:   return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}
