import Foundation

/// Builds the JSON filter object for the search_transactions FFI call.
struct TransactionSearchFilter: Encodable {
    let accountId: String
    var query: String?
    var categoryId: String?
    var transactionType: String?
    var minAmount: Int64?
    var maxAmount: Int64?
    var dateFrom: String?
    var dateTo: String?
    var limit: Int?
    var offset: Int?

    func toJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var results: [FinanceTransaction] = []
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var error: String?

    // Filter state
    @Published var queryText = ""
    @Published var selectedAccountId: String?
    @Published var selectedCategoryId: String?
    @Published var selectedType: TransactionType?
    @Published var minAmount: String = ""
    @Published var maxAmount: String = ""
    @Published var dateFrom: Date?
    @Published var dateTo: Date?

    // Data for pickers
    @Published var accounts: [Account] = []
    @Published var categories: [FinanceCategory] = []

    let userId: String

    init(userId: String) {
        self.userId = userId
    }

    func loadPickerData() {
        Task.detached { [userId = self.userId] in
            let accounts = (try? FinanceBridge.listAccounts(userId: userId)) ?? []
            let categories = (try? FinanceBridge.listCategories(userId: userId)) ?? []
            await MainActor.run {
                self.accounts = accounts
                self.categories = categories
                if self.selectedAccountId == nil, let first = accounts.first {
                    self.selectedAccountId = first.id
                }
            }
        }
    }

    func search() {
        guard let accountId = selectedAccountId else { return }
        isLoading = true
        error = nil

        var filter = TransactionSearchFilter(accountId: accountId)
        if !queryText.trimmingCharacters(in: .whitespaces).isEmpty {
            filter.query = queryText.trimmingCharacters(in: .whitespaces)
        }
        filter.categoryId = selectedCategoryId
        filter.transactionType = selectedType?.rawValue
        if let min = Int64(minAmount) { filter.minAmount = min * 100 } // dollars to cents
        if let max = Int64(maxAmount) { filter.maxAmount = max * 100 }
        if let from = dateFrom { filter.dateFrom = DateUtils.formatForAPI(from) }
        if let to = dateTo { filter.dateTo = DateUtils.formatForAPI(to) }
        filter.limit = 50

        guard let json = filter.toJSON() else {
            error = "Failed to build filter"
            isLoading = false
            return
        }

        Task.detached {
            do {
                let results = try FinanceBridge.searchTransactions(filterJson: json)
                await MainActor.run {
                    self.results = results
                    self.hasSearched = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.hasSearched = true
                    self.isLoading = false
                }
            }
        }
    }

    func clearFilters() {
        queryText = ""
        selectedCategoryId = nil
        selectedType = nil
        minAmount = ""
        maxAmount = ""
        dateFrom = nil
        dateTo = nil
        results = []
        hasSearched = false
    }
}
