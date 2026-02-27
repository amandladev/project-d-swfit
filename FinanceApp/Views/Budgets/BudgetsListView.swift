import SwiftUI

struct BudgetsListView: View {
    @StateObject private var viewModel: BudgetsViewModel
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
        _viewModel = StateObject(wrappedValue: BudgetsViewModel(accountId: accountId))
    }

    var body: some View {
        List {
            if viewModel.budgets.isEmpty && !viewModel.isLoading {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView(
                        "No Budgets",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Create budgets to track your spending limits")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Budgets")
                            .font(.headline)
                        Text("Create budgets to track your spending limits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }
            }

            ForEach(viewModel.budgets) { budget in
                BudgetRow(
                    budget: budget,
                    progress: viewModel.budgetProgress[budget.id],
                    categories: categoriesVM.categories,
                    currency: currency
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = viewModel.budgets[index]
                    viewModel.delete(id: item.id)
                }
            }
        }
        .navigationTitle("Budgets")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddBudgetView(
                viewModel: viewModel,
                categoriesVM: categoriesVM,
                currency: currency
            )
        }
        .onAppear { viewModel.load() }
        .refreshable { viewModel.load() }
        .overlay {
            if viewModel.isLoading && viewModel.budgets.isEmpty {
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

// MARK: - Budget Row

private struct BudgetRow: View {
    let budget: Budget
    let progress: BudgetProgress?
    let categories: [FinanceCategory]
    let currency: String

    private var category: FinanceCategory? {
        guard let catId = budget.categoryId else { return nil }
        return categories.first { $0.id == catId }
    }

    private var progressPercentage: Double {
        progress?.percentage ?? 0
    }

    private var progressColor: Color {
        if progressPercentage >= 1.2 { return .red }
        if progressPercentage >= 1.0 { return .red.opacity(0.8) }
        if progressPercentage >= 0.8 { return .orange }
        return .green
    }

    private var statusLabel: String {
        if progressPercentage >= 1.2 { return "Over Budget!" }
        if progressPercentage >= 1.0 { return "Budget Reached" }
        if progressPercentage >= 0.8 { return "Almost There" }
        return "On Track"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                if let cat = category {
                    Text(cat.icon)
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.name)
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 4) {
                        Text(budget.period.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if category == nil {
                            Text("• All Categories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                Text(statusLabel)
                    .font(.caption.weight(.medium))
                    .foregroundColor(progressColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(progressColor.opacity(0.12))
                    .cornerRadius(6)
            }

            // Progress bar
            if let prog = progress {
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor)
                                .frame(
                                    width: min(geometry.size.width, geometry.size.width * progressPercentage),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("Spent: \(CurrencyFormatter.format(cents: prog.spent, currency: currency))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Budget: \(CurrencyFormatter.format(cents: prog.budgetAmount, currency: currency))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if prog.remaining > 0 {
                        Text("\(CurrencyFormatter.format(cents: prog.remaining, currency: currency)) remaining")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Over by \(CurrencyFormatter.format(cents: -prog.remaining, currency: currency))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            } else {
                HStack {
                    Text("Limit: \(CurrencyFormatter.format(cents: budget.amount, currency: currency))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 6)
    }
}
