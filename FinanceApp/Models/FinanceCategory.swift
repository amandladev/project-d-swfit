import Foundation

struct FinanceCategory: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let icon: String
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    let syncStatus: String?
}
