import Foundation

@MainActor
class BudgetsViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var budgetProgress: [String: BudgetProgress] = [:] // budgetId → progress
    @Published var isLoading = false
    @Published var error: String?

    let accountId: String

    init(accountId: String) {
        self.accountId = accountId
    }

    func load() {
        isLoading = true
        error = nil
        let accountId = self.accountId

        Task.detached {
            do {
                let budgets = try FinanceBridge.listBudgets(accountId: accountId)

                // Fetch progress for each budget
                var progressMap: [String: BudgetProgress] = [:]
                for budget in budgets {
                    if let progress = try? FinanceBridge.getBudgetProgress(budgetId: budget.id) {
                        progressMap[budget.id] = progress
                    }
                }

                await MainActor.run {
                    self.budgets = budgets
                    self.budgetProgress = progressMap
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

    func create(
        categoryId: String?,
        name: String,
        amount: Int64,
        period: String,
        startDate: String
    ) {
        let accountId = self.accountId
        Task.detached {
            do {
                let budget = try FinanceBridge.createBudget(
                    accountId: accountId,
                    categoryId: categoryId,
                    name: name,
                    amount: amount,
                    period: period,
                    startDate: startDate
                )
                // Fetch progress immediately
                let progress = try? FinanceBridge.getBudgetProgress(budgetId: budget.id)

                await MainActor.run {
                    self.budgets.append(budget)
                    if let progress = progress {
                        self.budgetProgress[budget.id] = progress
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func delete(id: String) {
        Task.detached {
            do {
                try FinanceBridge.deleteBudget(id: id)
                await MainActor.run {
                    self.budgets.removeAll { $0.id == id }
                    self.budgetProgress.removeValue(forKey: id)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func refreshProgress(budgetId: String) {
        Task.detached {
            do {
                let progress = try FinanceBridge.getBudgetProgress(budgetId: budgetId)
                await MainActor.run {
                    self.budgetProgress[budgetId] = progress
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
