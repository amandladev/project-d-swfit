import SwiftUI

// MARK: - Date Range Filter Enum

enum DateRangeFilter: String, CaseIterable {
    case all = "All"
    case week = "Week"
    case month = "Month"
    case custom = "Custom"

    var displayName: String {
        switch self {
        case .all: return L10n.tr("dateFilter.all")
        case .week: return L10n.tr("dateFilter.week")
        case .month: return L10n.tr("dateFilter.month")
        case .custom: return L10n.tr("dateFilter.custom")
        }
    }
}

struct AccountDetailView: View {
    let account: Account
    let userId: String

    @StateObject private var transactionsVM: TransactionsViewModel
    @StateObject private var categoriesVM: CategoriesViewModel
    @StateObject private var tagsVM: TagsViewModel
    @State private var showAddTransaction = false
    @State private var editingTransaction: FinanceTransaction?
    @State private var searchText = ""
    @State private var dateFilter: DateRangeFilter = .all
    @State private var customFrom: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customTo: Date = Date()
    @State private var showCustomDatePicker = false

    init(account: Account, userId: String) {
        self.account = account
        self.userId = userId
        _transactionsVM = StateObject(wrappedValue: TransactionsViewModel(accountId: account.id))
        _categoriesVM = StateObject(wrappedValue: CategoriesViewModel(userId: userId))
        _tagsVM = StateObject(wrappedValue: TagsViewModel(userId: userId))
    }

    var body: some View {
        List {
            // Balance card
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.tr("accounts.currentBalance"))
                        .font(AppTheme.subheadlineFont)
                        .foregroundColor(.secondary)
                    AnimatedCurrencyText(
                        cents: transactionsVM.balance,
                        currency: account.currency,
                        font: AppTheme.displayFont(34),
                        color: .primary
                    )
                    HStack(spacing: 16) {
                        StatBadge(
                            label: L10n.tr("dashboard.income"),
                            value: totalIncome,
                            currency: account.currency,
                            color: AppTheme.income
                        )
                        StatBadge(
                            label: L10n.tr("dashboard.expenses"),
                            value: totalExpenses,
                            currency: account.currency,
                            color: AppTheme.expense
                        )
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
            }

            // Date range filter
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Picker(L10n.tr("dateFilter.period"), selection: $dateFilter) {
                        ForEach(DateRangeFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: dateFilter) { newValue in
                        applyDateFilter(newValue)
                    }

                    if dateFilter == .custom {
                        HStack {
                            DatePicker("From", selection: $customFrom, displayedComponents: .date)
                                .labelsHidden()
                            Text(L10n.tr("dateFilter.to"))
                                .foregroundColor(.secondary)
                            DatePicker("To", selection: $customTo, displayedComponents: .date)
                                .labelsHidden()
                            Button(L10n.tr("common.apply")) {
                                transactionsVM.loadTransactions(from: customFrom, to: customTo)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }

            // Quick Actions - Recurring & Budgets
            Section(L10n.tr("accountDetail.manage")) {
                NavigationLink {
                    RecurringTransactionsListView(
                        accountId: account.id,
                        accountName: account.name,
                        currency: account.currency,
                        categoriesVM: categoriesVM
                    )
                } label: {
                    Label(L10n.tr("accountDetail.recurringTransactions"), systemImage: "arrow.triangle.2.circlepath")
                }

                NavigationLink {
                    BudgetsListView(
                        accountId: account.id,
                        accountName: account.name,
                        currency: account.currency,
                        categoriesVM: categoriesVM
                    )
                } label: {
                    Label(L10n.tr("accountDetail.budgets"), systemImage: "chart.bar.doc.horizontal")
                }
            }

            // Transactions
            Section {
                if transactionsVM.isLoading && transactionsVM.transactions.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if filteredTransactions.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text(searchText.isEmpty ? L10n.tr("accountDetail.noTransactions") : L10n.tr("accountDetail.noMatches"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
                    ForEach(filteredTransactions) { transaction in
                        TransactionRowView(
                            transaction: transaction,
                            categories: categoriesVM.categories,
                            currency: account.currency
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingTransaction = transaction
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                transactionsVM.deleteTransaction(transactionId: transaction.id)
                            } label: {
                                Label(L10n.tr("common.delete"), systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                editingTransaction = transaction
                            } label: {
                                Label(L10n.tr("common.edit"), systemImage: "pencil")
                            }
                            .tint(AppTheme.accent)
                        }
                    }
                }
            } header: {
                HStack {
                    Text(L10n.tr("accountDetail.transactions"))
                    Spacer()
                    Text("\(filteredTransactions.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .searchable(text: $searchText, prompt: L10n.tr("accountDetail.searchPrompt"))
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(
                transactionsVM: transactionsVM,
                categoriesVM: categoriesVM,
                tagsVM: tagsVM,
                currency: account.currency
            )
        }
        .sheet(item: $editingTransaction) { transaction in
            EditTransactionView(
                transactionsVM: transactionsVM,
                categoriesVM: categoriesVM,
                tagsVM: tagsVM,
                transaction: transaction,
                currency: account.currency
            )
        }
        .onAppear {
            transactionsVM.loadTransactions()
            categoriesVM.loadCategories()
        }
        .refreshable {
            applyDateFilter(dateFilter)
        }
        .overlay {
            if transactionsVM.isLoading && transactionsVM.transactions.isEmpty {
                BrandedLoadingView()
            }
        }
        .alert(L10n.tr("common.error"), isPresented: Binding<Bool>(
            get: { transactionsVM.error != nil },
            set: { if !$0 { transactionsVM.error = nil } }
        )) {
            Button(L10n.tr("common.ok")) { transactionsVM.error = nil }
        } message: {
            Text(transactionsVM.error ?? "")
        }
    }

    // MARK: - Filtering

    private var filteredTransactions: [FinanceTransaction] {
        guard !searchText.isEmpty else { return transactionsVM.transactions }
        let query = searchText.lowercased()
        return transactionsVM.transactions.filter { txn in
            // Match description
            if txn.description.lowercased().contains(query) { return true }
            // Match category name
            if let cat = categoriesVM.categories.first(where: { $0.id == txn.categoryId }),
               cat.name.lowercased().contains(query) { return true }
            // Match amount (e.g. "10.50")
            let amountStr = String(format: "%.2f", CurrencyFormatter.toDecimal(cents: txn.amount))
            if amountStr.contains(query) { return true }
            // Match transaction type
            if txn.transactionType.lowercased().contains(query) { return true }
            return false
        }
    }

    private func applyDateFilter(_ filter: DateRangeFilter) {
        let calendar = Calendar.current
        let now = Date()
        switch filter {
        case .all:
            transactionsVM.loadTransactions()
        case .week:
            let from = calendar.date(byAdding: .day, value: -7, to: now)!
            transactionsVM.loadTransactions(from: from, to: now)
        case .month:
            let from = calendar.date(byAdding: .month, value: -1, to: now)!
            transactionsVM.loadTransactions(from: from, to: now)
        case .custom:
            transactionsVM.loadTransactions(from: customFrom, to: customTo)
        }
    }

    // MARK: - Computed

    private var totalIncome: Int64 {
        filteredTransactions
            .filter { $0.transactionType == TransactionType.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Int64 {
        filteredTransactions
            .filter { $0.transactionType == TransactionType.expense.rawValue }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let label: String
    let value: Int64
    let currency: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(AppTheme.captionFont)
                    .foregroundColor(.secondary)
            }
            Text(CurrencyFormatter.format(cents: value, currency: currency))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Transaction Row

struct TransactionRowView: View {
    let transaction: FinanceTransaction
    let categories: [FinanceCategory]
    let currency: String

    private var category: FinanceCategory? {
        categories.first { $0.id == transaction.categoryId }
    }

    private var isExpense: Bool {
        transaction.transactionType == TransactionType.expense.rawValue
    }

    private var isIncome: Bool {
        transaction.transactionType == TransactionType.income.rawValue
    }

    private var typeColor: Color {
        isExpense ? AppTheme.expense : (isIncome ? AppTheme.income : AppTheme.transfer)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Text(category?.icon ?? "💰")
                    .font(.title3)
            }

            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.description)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(category?.name ?? L10n.tr("transactions.uncategorized"))
                    Text("·")
                    Text(DateUtils.dateOnlyString(transaction.date))
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 3) {
                Text(CurrencyFormatter.format(
                    cents: isExpense ? -transaction.amount : transaction.amount,
                    currency: currency
                ))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(typeColor)

                Text(transaction.transactionType.capitalized)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(typeColor.opacity(0.08))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 3)
    }
}
