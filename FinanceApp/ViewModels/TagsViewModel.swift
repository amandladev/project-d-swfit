import Foundation

@MainActor
class TagsViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var error: String?

    let userId: String

    init(userId: String) {
        self.userId = userId
    }

    // MARK: - Load

    func loadTags() {
        isLoading = true
        error = nil

        Task.detached { [userId] in
            do {
                let tags = try FinanceBridge.listTags(userId: userId)
                await MainActor.run {
                    self.tags = tags
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Create

    func createTag(name: String, color: String?) {
        error = nil

        Task.detached { [userId] in
            do {
                let tag = try FinanceBridge.createTag(userId: userId, name: name, color: color)
                await MainActor.run {
                    self.tags.append(tag)
                    self.tags.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Update

    func updateTag(tagId: String, name: String?, color: String?) {
        error = nil

        var fields: [String: String] = [:]
        if let name = name { fields["name"] = name }
        if let color = color { fields["color"] = color }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: fields),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        Task.detached {
            do {
                let updated = try FinanceBridge.updateTag(tagId: tagId, updateJson: jsonString)
                await MainActor.run {
                    if let idx = self.tags.firstIndex(where: { $0.id == tagId }) {
                        self.tags[idx] = updated
                    }
                    self.tags.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Delete

    func deleteTag(tagId: String) {
        error = nil

        Task.detached {
            do {
                try FinanceBridge.deleteTag(tagId: tagId)
                await MainActor.run {
                    self.tags.removeAll { $0.id == tagId }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Transaction Tags

    /// Get all tags for a specific transaction.
    func getTransactionTags(transactionId: String) -> [Tag] {
        (try? FinanceBridge.getTransactionTags(transactionId: transactionId)) ?? []
    }

    /// Toggle a tag on/off for a transaction.
    func toggleTag(tagId: String, on transactionId: String, isAdding: Bool) {
        Task.detached {
            do {
                if isAdding {
                    try FinanceBridge.addTagToTransaction(transactionId: transactionId, tagId: tagId)
                } else {
                    try FinanceBridge.removeTagFromTransaction(transactionId: transactionId, tagId: tagId)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
