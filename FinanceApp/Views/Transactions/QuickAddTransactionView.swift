import SwiftUI

/// Compact quick-add transaction sheet — minimal taps to log an expense/income.
struct QuickAddTransactionView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss

    // Data
    @State private var accounts: [Account] = []
    @State private var categories: [FinanceCategory] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var error: String?
    @State private var saved = false

    // Form
    @State private var amount = ""
    @State private var description = ""
    @State private var transactionType: TransactionType = .expense
    @State private var selectedAccountId = ""
    @State private var selectedCategoryId = ""
    @State private var date = Date()
    @FocusState private var amountFocused: Bool

    private var selectedAccount: Account? {
        accounts.first { $0.id == selectedAccountId }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    BrandedLoadingView()
                    Spacer()
                } else if saved {
                    successView
                } else {
                    formContent
                }
            }
            .background(AppTheme.surfaceBackground.ignoresSafeArea())
            .navigationTitle(L10n.tr("quickAdd.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel")) { dismiss() }
                }
            }
            .onAppear { loadData() }
        }
    }

    // MARK: - Form

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Type toggle
                typeSelector
                    .padding(.top, 8)

                // Amount
                amountField

                // Description
                TextField(L10n.tr("quickAdd.whatWasItFor"), text: $description)
                    .font(.system(.body, design: .rounded))
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.sentences)

                // Account picker
                if accounts.count > 1 {
                    accountPicker
                }

                // Category quick-pick (horizontal scroll)
                categoryPicker

                // Date (collapsed by default — today)
                datePicker

                // Error
                if let error {
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(AppTheme.expense)
                }

                // Save button
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach([TransactionType.expense, .income], id: \.self) { type in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        transactionType = type
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.subheadline)
                        Text(type.displayName)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(transactionType == type ? typeColor.opacity(0.15) : Color.clear)
                    .foregroundColor(transactionType == type ? typeColor : .secondary)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Amount

    private var amountField: some View {
        HStack(spacing: 8) {
            Text(CurrencyFormatter.symbol(for: selectedAccount?.currency ?? "USD"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(typeColor)

            TextField("0.00", text: $amount)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .keyboardType(.decimalPad)
                .minimumScaleFactor(0.5)
                .focused($amountFocused)
                .onAppear { amountFocused = true }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(typeColor.opacity(0.06))
        .cornerRadius(16)
    }

    // MARK: - Account Picker

    private var accountPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("quickAdd.account"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(accounts) { account in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedAccountId = account.id
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(currencyFlag(for: account.currency))
                                    .font(.callout)
                                Text(account.name)
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedAccountId == account.id ? AppTheme.accent.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                            .foregroundColor(selectedAccountId == account.id ? AppTheme.accent : .primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedAccountId == account.id ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("quickAdd.category"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 10)], spacing: 10) {
                ForEach(categories) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategoryId = cat.id
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(cat.icon)
                                .font(.title2)
                            Text(cat.name)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedCategoryId == cat.id ? AppTheme.accent.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                        .foregroundColor(selectedCategoryId == cat.id ? AppTheme.accent : .primary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedCategoryId == cat.id ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Date Picker

    private var datePicker: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.secondary)
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveTransaction()
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.tr("quickAdd.add %@", transactionType.displayName))
                        .fontWeight(.semibold)
                }
            }
            .font(.system(.body, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? typeColor : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(!isValid || isSaving)
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.income.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(AppTheme.income)
            }
            .transition(.scale.combined(with: .opacity))

            Text(L10n.tr("quickAdd.transactionAdded"))
                .font(AppTheme.displayFont(22))

            Text(CurrencyFormatter.format(
                cents: CurrencyFormatter.toCents(amount) ?? 0,
                currency: selectedAccount?.currency ?? "USD"
            ))
            .font(.system(.title2, design: .rounded).weight(.bold))
            .foregroundColor(typeColor)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    // Reset for another
                    withAnimation {
                        saved = false
                        amount = ""
                        description = ""
                        selectedCategoryId = ""
                        amountFocused = true
                    }
                } label: {
                    Text(L10n.tr("quickAdd.addAnother"))
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent.opacity(0.12))
                        .foregroundColor(AppTheme.accent)
                        .cornerRadius(14)
                }

                Button {
                    dismiss()
                } label: {
                    Text(L10n.tr("quickAdd.done"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private var typeColor: Color {
        transactionType == .expense ? AppTheme.expense : AppTheme.income
    }

    private var isValid: Bool {
        !amount.isEmpty &&
        CurrencyFormatter.toCents(amount) != nil &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedAccountId.isEmpty &&
        !selectedCategoryId.isEmpty
    }

    private func currencyFlag(for code: String) -> String {
        switch code.uppercased() {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "PEN": return "🇵🇪"
        case "CLP": return "🇨🇱"
        case "COP": return "🇨🇴"
        case "GBP": return "🇬🇧"
        case "BRL": return "🇧🇷"
        case "MXN": return "🇲🇽"
        case "ARS": return "🇦🇷"
        default:    return "💱"
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        Task.detached {
            do {
                let accounts = try FinanceBridge.listAccounts(userId: userId)
                let categories = try FinanceBridge.listCategories(userId: userId)

                await MainActor.run {
                    self.accounts = accounts
                    self.categories = categories
                    if let first = accounts.first {
                        self.selectedAccountId = first.id
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Save

    private func saveTransaction() {
        guard let cents = CurrencyFormatter.toCents(amount) else { return }
        isSaving = true
        error = nil

        let accountId = selectedAccountId
        let categoryId = selectedCategoryId
        let type = transactionType
        let desc = description.trimmingCharacters(in: .whitespaces)
        let dateStr = DateUtils.formatForAPI(date)

        Task.detached {
            do {
                try FinanceBridge.createTransaction(
                    accountId: accountId,
                    categoryId: categoryId,
                    amount: cents,
                    transactionType: type.rawValue,
                    description: desc,
                    date: dateStr
                )

                await MainActor.run {
                    isSaving = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        saved = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
