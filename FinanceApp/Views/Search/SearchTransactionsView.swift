import SwiftUI

struct SearchTransactionsView: View {
    @StateObject private var viewModel: SearchViewModel
    @State private var showFilters = false

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Active filter chips
                if hasActiveFilters {
                    activeFiltersBar
                }

                // Results
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.accent)
                    Spacer()
                } else if !viewModel.hasSearched {
                    emptyPrompt
                } else if viewModel.results.isEmpty {
                    noResults
                } else {
                    resultsList
                }
            }
            .background(AppTheme.surfaceBackground.ignoresSafeArea())
            .navigationTitle("Search")
            .onAppear { viewModel.loadPickerData() }
            .sheet(isPresented: $showFilters) {
                FilterSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.body)

                TextField("Search transactions...", text: $viewModel.queryText)
                    .font(.system(.body, design: .rounded))
                    .submitLabel(.search)
                    .onSubmit { viewModel.search() }

                if !viewModel.queryText.isEmpty {
                    Button {
                        viewModel.queryText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .padding(10)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)

            Button {
                showFilters = true
            } label: {
                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(hasActiveFilters ? AppTheme.accent : .secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Active Filters Bar

    private var hasActiveFilters: Bool {
        viewModel.selectedCategoryId != nil ||
        viewModel.selectedType != nil ||
        !viewModel.minAmount.isEmpty ||
        !viewModel.maxAmount.isEmpty ||
        viewModel.dateFrom != nil ||
        viewModel.dateTo != nil
    }

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let type = viewModel.selectedType {
                    filterChip(type.displayName, icon: type.icon) {
                        viewModel.selectedType = nil
                    }
                }

                if let catId = viewModel.selectedCategoryId,
                   let cat = viewModel.categories.first(where: { $0.id == catId }) {
                    filterChip("\(cat.icon) \(cat.name)") {
                        viewModel.selectedCategoryId = nil
                    }
                }

                if !viewModel.minAmount.isEmpty || !viewModel.maxAmount.isEmpty {
                    let text = amountRangeText
                    filterChip(text, icon: "dollarsign.circle") {
                        viewModel.minAmount = ""
                        viewModel.maxAmount = ""
                    }
                }

                if viewModel.dateFrom != nil || viewModel.dateTo != nil {
                    filterChip("Date range", icon: "calendar") {
                        viewModel.dateFrom = nil
                        viewModel.dateTo = nil
                    }
                }

                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear all")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(AppTheme.expense)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    private var amountRangeText: String {
        if !viewModel.minAmount.isEmpty && !viewModel.maxAmount.isEmpty {
            return "$\(viewModel.minAmount) – $\(viewModel.maxAmount)"
        } else if !viewModel.minAmount.isEmpty {
            return "≥ $\(viewModel.minAmount)"
        } else {
            return "≤ $\(viewModel.maxAmount)"
        }
    }

    private func filterChip(_ text: String, icon: String? = nil, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.medium))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
        }
        .foregroundColor(AppTheme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppTheme.accent.opacity(0.12))
        .cornerRadius(20)
    }

    // MARK: - States

    private var emptyPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Search your transactions")
                .font(AppTheme.headlineFont)
                .foregroundColor(.secondary)
            Text("Type a description or use filters to find transactions")
                .font(AppTheme.captionFont)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var noResults: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No results found")
                .font(AppTheme.headlineFont)
                .foregroundColor(.secondary)
            Text("Try adjusting your filters or search term")
                .font(AppTheme.captionFont)
                .foregroundColor(.secondary.opacity(0.7))
            Button("Clear Filters") {
                viewModel.clearFilters()
            }
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundColor(AppTheme.accent)
            Spacer()
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                HStack {
                    Text("\(viewModel.results.count) results")
                        .font(AppTheme.captionFont)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                ForEach(viewModel.results) { txn in
                    SearchResultRow(
                        transaction: txn,
                        categories: viewModel.categories,
                        accounts: viewModel.accounts
                    )

                    if txn.id != viewModel.results.last?.id {
                        Divider()
                            .padding(.leading, 64)
                            .opacity(0.5)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let transaction: FinanceTransaction
    let categories: [FinanceCategory]
    let accounts: [Account]

    private var category: FinanceCategory? {
        categories.first { $0.id == transaction.categoryId }
    }

    private var account: Account? {
        accounts.first { $0.id == transaction.accountId }
    }

    private var isExpense: Bool {
        transaction.transactionType == "expense"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((isExpense ? AppTheme.expense : AppTheme.income).opacity(0.12))
                    .frame(width: 42, height: 42)
                Text(category?.icon ?? "💰")
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.description)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(DateUtils.dateOnlyString(transaction.date))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                    if let acc = account {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(acc.name)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(
                    cents: isExpense ? -transaction.amount : transaction.amount,
                    currency: account?.currency ?? "USD"
                ))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(isExpense ? AppTheme.expense : AppTheme.income)

                if let cat = category {
                    Text(cat.name)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Filter Sheet

private struct FilterSheet: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Account
                Section("Account") {
                    Picker("Account", selection: $viewModel.selectedAccountId) {
                        ForEach(viewModel.accounts) { acc in
                            Text(acc.name).tag(acc.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Transaction Type
                Section("Type") {
                    Picker("Transaction Type", selection: $viewModel.selectedType) {
                        Text("All").tag(nil as TransactionType?)
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type as TransactionType?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Category
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategoryId) {
                        Text("All").tag(nil as String?)
                        ForEach(viewModel.categories) { cat in
                            Text("\(cat.icon) \(cat.name)").tag(cat.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Amount Range
                Section("Amount Range") {
                    HStack {
                        TextField("Min ($)", text: $viewModel.minAmount)
                            .keyboardType(.numberPad)
                            .font(.system(.body, design: .rounded))
                        Text("–")
                            .foregroundColor(.secondary)
                        TextField("Max ($)", text: $viewModel.maxAmount)
                            .keyboardType(.numberPad)
                            .font(.system(.body, design: .rounded))
                    }
                }

                // Date Range
                Section("Date Range") {
                    Toggle("From date", isOn: Binding(
                        get: { viewModel.dateFrom != nil },
                        set: { viewModel.dateFrom = $0 ? Calendar.current.date(byAdding: .month, value: -1, to: Date()) : nil }
                    ))
                    if let _ = viewModel.dateFrom {
                        DatePicker("From", selection: Binding(
                            get: { viewModel.dateFrom ?? Date() },
                            set: { viewModel.dateFrom = $0 }
                        ), displayedComponents: .date)
                    }

                    Toggle("To date", isOn: Binding(
                        get: { viewModel.dateTo != nil },
                        set: { viewModel.dateTo = $0 ? Date() : nil }
                    ))
                    if let _ = viewModel.dateTo {
                        DatePicker("To", selection: Binding(
                            get: { viewModel.dateTo ?? Date() },
                            set: { viewModel.dateTo = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(AppTheme.expense)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Search") {
                        viewModel.search()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}
