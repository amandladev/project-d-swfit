import Foundation

struct Account: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let currency: String
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    let syncStatus: String?
}
