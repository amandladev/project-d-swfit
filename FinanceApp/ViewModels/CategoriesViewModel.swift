import Foundation

@MainActor
class CategoriesViewModel: ObservableObject {
    @Published var categories: [FinanceCategory] = []
    @Published var isLoading = false
    @Published var error: String?

    let userId: String

    init(userId: String) {
        self.userId = userId
    }

    // MARK: - Load

    func loadCategories() {
        isLoading = true
        error = nil

        Task.detached { [userId] in
            do {
                let categories = try FinanceBridge.listCategories(userId: userId)
                await MainActor.run {
                    self.categories = categories
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

    func createCategory(name: String, icon: String) {
        error = nil

        Task.detached { [userId] in
            do {
                let _ = try FinanceBridge.createCategory(userId: userId, name: name, icon: icon)
                await MainActor.run {
                    self.loadCategories()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Delete

    func deleteCategory(categoryId: String) {
        error = nil

        Task.detached {
            do {
                try FinanceBridge.deleteCategory(categoryId: categoryId)
                await MainActor.run {
                    self.categories.removeAll { $0.id == categoryId }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
