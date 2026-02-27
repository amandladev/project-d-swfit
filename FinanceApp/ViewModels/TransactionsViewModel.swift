import Foundation
import WidgetKit

@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [FinanceTransaction] = []
    @Published var balance: Int64 = 0
    @Published var isLoading = false
    @Published var error: String?

    let accountId: String

    init(accountId: String) {
        self.accountId = accountId
    }

    // MARK: - Load

    func loadTransactions() {
        isLoading = true
        error = nil

        Task.detached { [accountId] in
            do {
                let transactions = try FinanceBridge.listTransactions(accountId: accountId)
                let balance = try FinanceBridge.getBalance(accountId: accountId)

                await MainActor.run {
                    self.transactions = transactions
                    self.balance = balance.balance
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

    func createTransaction(
        categoryId: String,
        amount: Int64,
        type: TransactionType,
        description: String,
        date: Date
    ) {
        error = nil

        Task.detached { [accountId] in
            do {
                let dateString = DateUtils.toRFC3339(date)
                let _ = try FinanceBridge.createTransaction(
                    accountId: accountId,
                    categoryId: categoryId,
                    amount: amount,
                    transactionType: type.rawValue,
                    description: description,
                    date: dateString
                )
                await MainActor.run {
                    self.loadTransactions()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Edit

    func editTransaction(
        transactionId: String,
        amount: Int64,
        type: TransactionType,
        description: String,
        categoryId: String,
        date: Date
    ) {
        error = nil

        Task.detached {
            do {
                let dateString = DateUtils.toRFC3339(date)
                let _ = try FinanceBridge.editTransaction(
                    transactionId: transactionId,
                    amount: amount,
                    transactionType: type.rawValue,
                    description: description,
                    categoryId: categoryId,
                    date: dateString
                )
                await MainActor.run {
                    self.loadTransactions()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Delete

    func deleteTransaction(transactionId: String) {
        error = nil

        Task.detached {
            do {
                try FinanceBridge.deleteTransaction(transactionId: transactionId)
                await MainActor.run {
                    self.transactions.removeAll { $0.id == transactionId }
                    self.loadTransactions()  // Reload to refresh balance
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Filter by Date Range

    func loadTransactions(from: Date, to: Date) {
        isLoading = true
        error = nil

        Task.detached { [accountId] in
            do {
                let transactions = try FinanceBridge.listTransactionsByDateRange(
                    accountId: accountId,
                    from: DateUtils.toRFC3339(from),
                    to: DateUtils.toRFC3339(to)
                )
                let balance = try FinanceBridge.getBalance(accountId: accountId)

                await MainActor.run {
                    self.transactions = transactions
                    self.balance = balance.balance
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
}
