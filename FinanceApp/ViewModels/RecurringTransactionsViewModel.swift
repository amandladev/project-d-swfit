import Foundation

@MainActor
class RecurringTransactionsViewModel: ObservableObject {
    @Published var recurringTransactions: [RecurringTransaction] = []
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
                let items = try FinanceBridge.listRecurringTransactions(accountId: accountId)
                await MainActor.run {
                    self.recurringTransactions = items
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
        categoryId: String,
        amount: Int64,
        transactionType: String,
        description: String,
        frequency: String,
        startDate: String,
        endDate: String?
    ) {
        let accountId = self.accountId
        Task.detached {
            do {
                let item = try FinanceBridge.createRecurringTransaction(
                    accountId: accountId,
                    categoryId: categoryId,
                    amount: amount,
                    transactionType: transactionType,
                    description: description,
                    frequency: frequency,
                    startDate: startDate,
                    endDate: endDate
                )
                await MainActor.run {
                    self.recurringTransactions.append(item)
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
                try FinanceBridge.deleteRecurringTransaction(id: id)
                await MainActor.run {
                    self.recurringTransactions.removeAll { $0.id == id }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func processDue() {
        Task.detached {
            do {
                let _ = try FinanceBridge.processDueRecurringTransactions()
                let accountId = await self.accountId
                let items = try FinanceBridge.listRecurringTransactions(accountId: accountId)
                await MainActor.run {
                    self.recurringTransactions = items
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
