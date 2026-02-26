import SwiftUI

struct AccountsListView: View {
    @StateObject private var viewModel: AccountsViewModel
    @State private var showAddAccount = false

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: AccountsViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView()
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
            .navigationTitle("Accounts")
            .toolbar {
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
            .onAppear {
                viewModel.loadAccounts()
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
            // Summary card
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Balance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(CurrencyFormatter.format(cents: totalBalance))
                            .font(.title.bold())
                    }
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            }

            // Account rows
            Section("My Accounts") {
                ForEach(viewModel.accounts) { account in
                    NavigationLink {
                        AccountDetailView(account: account, userId: viewModel.userId)
                    } label: {
                        AccountRowView(
                            account: account,
                            balance: viewModel.balances[account.id] ?? 0
                        )
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteAccount(accountId: viewModel.accounts[index].id)
                    }
                }
            }
        }
    }

    private var totalBalance: Int64 {
        viewModel.balances.values.reduce(0, +)
    }
}

// MARK: - Account Row

struct AccountRowView: View {
    let account: Account
    let balance: Int64

    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(currencyColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(currencyFlag)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                Text(account.currency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            CurrencyText(cents: balance, currency: account.currency)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(balance >= 0 ? .primary : .red)
        }
        .padding(.vertical, 4)
    }

    private var currencyColor: Color {
        switch account.currency {
        case "USD": return .green
        case "EUR": return .blue
        case "GBP": return .purple
        case "MXN": return .orange
        default:    return .gray
        }
    }

    private var currencyFlag: String {
        switch account.currency {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "MXN": return "🇲🇽"
        case "CAD": return "🇨🇦"
        case "JPY": return "🇯🇵"
        case "BRL": return "🇧🇷"
        case "ARS": return "🇦🇷"
        default:    return "💰"
        }
    }
}
