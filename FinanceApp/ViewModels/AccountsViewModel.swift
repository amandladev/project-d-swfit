import Foundation

@MainActor
class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var balances: [String: Int64] = [:]  // accountId → balance in cents
    @Published var isLoading = false
    @Published var error: String?

    let userId: String

    init(userId: String) {
        self.userId = userId
    }

    // MARK: - Load

    func loadAccounts() {
        isLoading = true
        error = nil

        Task.detached { [userId] in
            do {
                let accounts = try FinanceBridge.listAccounts(userId: userId)

                // Fetch balance for each account
                var balances: [String: Int64] = [:]
                for account in accounts {
                    if let bal = try? FinanceBridge.getBalance(accountId: account.id) {
                        balances[account.id] = bal.balance
                    }
                }

                await MainActor.run {
                    self.accounts = accounts
                    self.balances = balances
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

    func createAccount(name: String, currency: String) {
        error = nil

        Task.detached { [userId] in
            do {
                let _ = try FinanceBridge.createAccount(userId: userId, name: name, currency: currency)
                await MainActor.run {
                    self.loadAccounts()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Delete

    func deleteAccount(accountId: String) {
        error = nil

        Task.detached {
            do {
                try FinanceBridge.deleteAccount(accountId: accountId)
                await MainActor.run {
                    self.accounts.removeAll { $0.id == accountId }
                    self.balances.removeValue(forKey: accountId)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
