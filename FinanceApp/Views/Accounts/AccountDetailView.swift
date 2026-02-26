import SwiftUI

struct AccountDetailView: View {
    let account: Account
    let userId: String

    @StateObject private var transactionsVM: TransactionsViewModel
    @StateObject private var categoriesVM: CategoriesViewModel
    @State private var showAddTransaction = false

    init(account: Account, userId: String) {
        self.account = account
        self.userId = userId
        _transactionsVM = StateObject(wrappedValue: TransactionsViewModel(accountId: account.id))
        _categoriesVM = StateObject(wrappedValue: CategoriesViewModel(userId: userId))
    }

    var body: some View {
        List {
            // Balance card
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    CurrencyText(cents: transactionsVM.balance, currency: account.currency)
                        .font(.system(size: 34, weight: .bold))
                    HStack(spacing: 16) {
                        StatBadge(
                            label: "Income",
                            value: totalIncome,
                            currency: account.currency,
                            color: .green
                        )
                        StatBadge(
                            label: "Expenses",
                            value: totalExpenses,
                            currency: account.currency,
                            color: .red
                        )
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
            }

            // Transactions
            Section {
                if transactionsVM.isLoading && transactionsVM.transactions.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if transactionsVM.transactions.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No transactions yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
                    ForEach(transactionsVM.transactions) { transaction in
                        TransactionRowView(
                            transaction: transaction,
                            categories: categoriesVM.categories,
                            currency: account.currency
                        )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            transactionsVM.deleteTransaction(
                                transactionId: transactionsVM.transactions[index].id
                            )
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Transactions")
                    Spacer()
                    Text("\(transactionsVM.transactions.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
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
                currency: account.currency
            )
        }
        .onAppear {
            transactionsVM.loadTransactions()
            categoriesVM.loadCategories()
        }
        .refreshable {
            transactionsVM.loadTransactions()
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { transactionsVM.error != nil },
            set: { if !$0 { transactionsVM.error = nil } }
        )) {
            Button("OK") { transactionsVM.error = nil }
        } message: {
            Text(transactionsVM.error ?? "")
        }
    }

    // MARK: - Computed

    private var totalIncome: Int64 {
        transactionsVM.transactions
            .filter { $0.transactionType == TransactionType.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Int64 {
        transactionsVM.transactions
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
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(CurrencyFormatter.format(cents: value, currency: currency))
                .font(.subheadline.weight(.medium))
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

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Text(category?.icon ?? "💰")
                .font(.title2)
                .frame(width: 36)

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(category?.name ?? "Uncategorized")
                    Text("·")
                    Text(DateUtils.dateOnlyString(transaction.date))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(
                    cents: isExpense ? -transaction.amount : transaction.amount,
                    currency: currency
                ))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isExpense ? .red : (isIncome ? .green : .blue))

                Text(transaction.transactionType.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
