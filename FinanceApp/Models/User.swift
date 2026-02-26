import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    let syncStatus: String?
}
