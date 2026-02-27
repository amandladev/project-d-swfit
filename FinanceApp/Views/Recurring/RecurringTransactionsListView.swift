import SwiftUI

struct RecurringTransactionsListView: View {
    @StateObject private var viewModel: RecurringTransactionsViewModel
    @ObservedObject var categoriesVM: CategoriesViewModel
    let accountId: String
    let accountName: String
    let currency: String

    @State private var showAddSheet = false

    init(accountId: String, accountName: String, currency: String, categoriesVM: CategoriesViewModel) {
        self.accountId = accountId
        self.accountName = accountName
        self.currency = currency
        self.categoriesVM = categoriesVM
        _viewModel = StateObject(wrappedValue: RecurringTransactionsViewModel(accountId: accountId))
    }

    var body: some View {
        List {
            if viewModel.recurringTransactions.isEmpty && !viewModel.isLoading {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView(
                        "No Recurring Transactions",
                        systemImage: "arrow.triangle.2.circlepath",
                        description: Text("Set up recurring transactions to automate your finances")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Recurring Transactions")
                            .font(.headline)
                        Text("Set up recurring transactions to automate your finances")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }
            }

            ForEach(viewModel.recurringTransactions) { recurring in
                RecurringTransactionRow(
                    recurring: recurring,
                    categories: categoriesVM.categories,
                    currency: currency
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = viewModel.recurringTransactions[index]
                    viewModel.delete(id: item.id)
                }
            }
        }
        .navigationTitle("Recurring")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.processDue()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Process due transactions")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRecurringTransactionView(
                viewModel: viewModel,
                categoriesVM: categoriesVM,
                currency: currency
            )
        }
        .onAppear { viewModel.load() }
        .refreshable { viewModel.load() }
        .overlay {
            if viewModel.isLoading && viewModel.recurringTransactions.isEmpty {
                ProgressView()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
}

// MARK: - Row

private struct RecurringTransactionRow: View {
    let recurring: RecurringTransaction
    let categories: [FinanceCategory]
    let currency: String

    private var category: FinanceCategory? {
        categories.first { $0.id == recurring.categoryId }
    }

    private var isExpense: Bool {
        recurring.transactionType == "expense"
    }

    private var isActive: Bool {
        recurring.isActive ?? true
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(category?.icon ?? "🔄")
                    .font(.title2)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recurring.description)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    if !isActive {
                        Text("PAUSED")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    Label(recurring.frequency.capitalized, systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let nextDue = recurring.nextDueDate {
                        Text("Next: \(DateUtils.dateOnlyString(nextDue))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            Text(CurrencyFormatter.format(
                cents: isExpense ? -recurring.amount : recurring.amount,
                currency: currency
            ))
            .font(.subheadline.weight(.semibold))
            .foregroundColor(isExpense ? .red : .green)
        }
        .padding(.vertical, 4)
        .opacity(isActive ? 1 : 0.6)
    }
}
