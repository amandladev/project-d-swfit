import SwiftUI

struct AccountsListView: View {
    @StateObject private var viewModel: AccountsViewModel
    @StateObject private var categoriesVM: CategoriesViewModel
    @State private var showAddAccount = false
    @State private var showTransfer = false

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: AccountsViewModel(userId: userId))
        _categoriesVM = StateObject(wrappedValue: CategoriesViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    BrandedLoadingView()
                } else if viewModel.accounts.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "No Accounts",
                        message: "Create your first account to start tracking your finances."
                    )
                } else {
                    accountsList
                }
            }
            .background(AppTheme.surfaceBackground.ignoresSafeArea())
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showTransfer = true
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .disabled(viewModel.accounts.count < 2)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountView(viewModel: viewModel)
            }
            .sheet(isPresented: $showTransfer) {
                TransferView(
                    accountsVM: viewModel,
                    categoriesVM: categoriesVM
                )
            }
            .onAppear {
                viewModel.loadAccounts()
                categoriesVM.loadCategories()
            }
            .refreshable {
                viewModel.loadAccounts()
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    // MARK: - Accounts List

    private var accountsList: some View {
        List {
            // Per-currency balance summary
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Balance by Currency")
                        .font(AppTheme.subheadlineFont)
                        .foregroundColor(.secondary)

                    ForEach(balancesByCurrency, id: \.currency) { entry in
                        HStack {
                            Text(entry.currency)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.10))
                                .cornerRadius(6)

                            Spacer()

                            AnimatedCurrencyText(
                                cents: entry.total,
                                currency: entry.currency,
                                font: AppTheme.displayFont(22),
                                color: entry.total >= 0 ? .primary : AppTheme.expense
                            )
                        }
                    }
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
            }

            // Account rows
            Section {
                ForEach(viewModel.accounts) { account in
                    NavigationLink {
                        AccountDetailView(account: account, userId: viewModel.userId)
                    } label: {
                        AccountRowView(
                            account: account,
                            balance: viewModel.balances[account.id] ?? 0
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteAccount(accountId: account.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text("My Accounts")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var balancesByCurrency: [(currency: String, total: Int64)] {
        var totals: [String: Int64] = [:]
        for account in viewModel.accounts {
            let bal = viewModel.balances[account.id] ?? 0
            totals[account.currency, default: 0] += bal
        }
        return totals.map { (currency: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
}

// MARK: - Account Row

struct AccountRowView: View {
    let account: Account
    let balance: Int64

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(currencyColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(currencyFlag)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(account.name)
                    .font(.system(.headline, design: .rounded))
                Text(account.currency)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            Spacer()

            AnimatedCurrencyText(
                cents: balance,
                currency: account.currency,
                font: .system(.subheadline, design: .rounded).weight(.semibold),
                color: balance >= 0 ? .primary : AppTheme.expense
            )
        }
        .padding(.vertical, 6)
    }

    private var currencyColor: Color {
        switch account.currency {
        case "USD": return .green
        case "EUR": return .blue
        case "GBP": return .purple
        case "MXN": return .orange
        case "PEN": return .red
        case "CLP": return .red
        case "COP": return .yellow
        default:    return .gray
        }
    }

    private var currencyFlag: String {
        switch account.currency {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "MXN": return "🇲🇽"
        case "PEN": return "🇵🇪"
        case "CAD": return "🇨🇦"
        case "JPY": return "🇯🇵"
        case "BRL": return "🇧🇷"
        case "ARS": return "🇦🇷"
        case "CLP": return "🇨🇱"
        case "COP": return "🇨🇴"
        default:    return "💰"
        }
    }
}
