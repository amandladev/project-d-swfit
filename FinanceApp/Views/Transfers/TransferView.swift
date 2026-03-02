import SwiftUI

/// Transfer money between two accounts belonging to the same user.
struct TransferView: View {
    @ObservedObject var accountsVM: AccountsViewModel
    @ObservedObject var categoriesVM: CategoriesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fromAccountId = ""
    @State private var toAccountId = ""
    @State private var amount = ""
    @State private var description = "Transfer"
    @State private var date = Date()
    @State private var isProcessing = false
    @State private var error: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                // From / To
                Section(L10n.tr("transfer.details")) {
                    Picker(L10n.tr("transfer.from"), selection: $fromAccountId) {
                        Text(L10n.tr("transfer.selectAccount")).tag("")
                        ForEach(accountsVM.accounts) { account in
                            HStack {
                                Text(account.name)
                                Text("(\(account.currency))")
                                    .foregroundColor(.secondary)
                            }
                            .tag(account.id)
                        }
                    }

                    Picker(L10n.tr("transfer.to"), selection: $toAccountId) {
                        Text(L10n.tr("transfer.selectAccount")).tag("")
                        ForEach(availableDestinations) { account in
                            HStack {
                                Text(account.name)
                                Text("(\(account.currency))")
                                    .foregroundColor(.secondary)
                            }
                            .tag(account.id)
                        }
                    }
                }

                // Amount
                Section(L10n.tr("transfer.amount")) {
                    HStack {
                        if let fromAccount = selectedFromAccount {
                            Text(CurrencyFormatter.symbol(for: fromAccount.currency))
                                .foregroundColor(.secondary)
                                .font(.title3)
                        }
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                    }

                    if let fromAccount = selectedFromAccount,
                       let balance = accountsVM.balances[fromAccount.id] {
                        HStack {
                            Text(L10n.tr("transfer.available"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.format(cents: balance, currency: fromAccount.currency))
                                .font(.caption.weight(.medium))
                                .foregroundColor(balance > 0 ? .green : .red)
                        }
                    }
                }

                // Description & date
                Section(L10n.tr("transactions.details")) {
                    TextField(L10n.tr("transactions.description"), text: $description)
                        .textInputAutocapitalization(.sentences)

                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // Summary
                if isValid {
                    Section(L10n.tr("transfer.summary")) {
                        summaryView
                    }
                }
            }
            .navigationTitle(L10n.tr("transfer.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("transfer.title")) {
                        executeTransfer()
                    }
                    .disabled(!isValid || isProcessing)
                    .fontWeight(.semibold)
                }
            }
            .alert(L10n.tr("transfer.complete"), isPresented: $showSuccess) {
                Button(L10n.tr("quickAdd.done")) { dismiss() }
            } message: {
                Text(L10n.tr("transfer.successMessage"))
            }
            .alert(L10n.tr("common.error"), isPresented: Binding<Bool>(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button(L10n.tr("common.ok")) { error = nil }
            } message: {
                Text(error ?? "")
            }
            .overlay {
                if isProcessing {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                    ProgressView(L10n.tr("transfer.transferring"))
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Summary

    private var summaryView: some View {
        VStack(spacing: 12) {
            if let from = selectedFromAccount, let to = selectedToAccount,
               let cents = CurrencyFormatter.toCents(amount) {
                HStack {
                    VStack(spacing: 4) {
                        Text(from.name)
                            .font(.headline)
                        Text(from.currency)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text(CurrencyFormatter.format(cents: cents, currency: from.currency))
                            .font(.subheadline.weight(.semibold))
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text(to.name)
                            .font(.headline)
                        Text(to.currency)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Logic

    private var selectedFromAccount: Account? {
        accountsVM.accounts.first { $0.id == fromAccountId }
    }

    private var selectedToAccount: Account? {
        accountsVM.accounts.first { $0.id == toAccountId }
    }

    private var availableDestinations: [Account] {
        accountsVM.accounts.filter { $0.id != fromAccountId }
    }

    private var isValid: Bool {
        !fromAccountId.isEmpty &&
        !toAccountId.isEmpty &&
        fromAccountId != toAccountId &&
        !amount.isEmpty &&
        CurrencyFormatter.toCents(amount) != nil &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func executeTransfer() {
        guard let cents = CurrencyFormatter.toCents(amount) else { return }
        isProcessing = true
        error = nil

        // Pick the first transfer-like category, or any category as fallback
        let transferCatId = categoriesVM.categories.first(where: {
            $0.name.lowercased().contains("transfer") || $0.name.lowercased().contains("other")
        })?.id ?? categoriesVM.categories.first?.id ?? ""

        let dateStr = DateUtils.toRFC3339(date)
        let desc = description.trimmingCharacters(in: .whitespaces)
        let fromId = fromAccountId
        let toId = toAccountId

        Task.detached {
            do {
                // Create expense from source
                let _ = try FinanceBridge.createTransaction(
                    accountId: fromId,
                    categoryId: transferCatId,
                    amount: cents,
                    transactionType: "transfer",
                    description: desc,
                    date: dateStr
                )

                // Create income in destination
                let _ = try FinanceBridge.createTransaction(
                    accountId: toId,
                    categoryId: transferCatId,
                    amount: cents,
                    transactionType: "transfer",
                    description: desc,
                    date: dateStr
                )

                await MainActor.run {
                    self.isProcessing = false
                    self.accountsVM.loadAccounts()
                    self.showSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
