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
                Section("Transfer Details") {
                    Picker("From", selection: $fromAccountId) {
                        Text("Select account").tag("")
                        ForEach(accountsVM.accounts) { account in
                            HStack {
                                Text(account.name)
                                Text("(\(account.currency))")
                                    .foregroundColor(.secondary)
                            }
                            .tag(account.id)
                        }
                    }

                    Picker("To", selection: $toAccountId) {
                        Text("Select account").tag("")
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
                Section("Amount") {
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
                            Text("Available:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.format(cents: balance, currency: fromAccount.currency))
                                .font(.caption.weight(.medium))
                                .foregroundColor(balance > 0 ? .green : .red)
                        }
                    }
                }

                // Description & date
                Section("Details") {
                    TextField("Description", text: $description)
                        .textInputAutocapitalization(.sentences)

                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // Summary
                if isValid {
                    Section("Summary") {
                        summaryView
                    }
                }
            }
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") {
                        executeTransfer()
                    }
                    .disabled(!isValid || isProcessing)
                    .fontWeight(.semibold)
                }
            }
            .alert("Transfer Complete", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Money was transferred successfully.")
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "")
            }
            .overlay {
                if isProcessing {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                    ProgressView("Transferring...")
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
