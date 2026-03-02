import SwiftUI

struct EditTransactionView: View {
    @ObservedObject var transactionsVM: TransactionsViewModel
    @ObservedObject var categoriesVM: CategoriesViewModel
    @ObservedObject var tagsVM: TagsViewModel
    let transaction: FinanceTransaction
    let currency: String

    @Environment(\.dismiss) private var dismiss

    @State private var amount: String
    @State private var description: String
    @State private var transactionType: TransactionType
    @State private var selectedCategoryId: String
    @State private var selectedTagIds: Set<String>
    @State private var originalTagIds: Set<String>
    @State private var date: Date

    init(
        transactionsVM: TransactionsViewModel,
        categoriesVM: CategoriesViewModel,
        tagsVM: TagsViewModel,
        transaction: FinanceTransaction,
        currency: String
    ) {
        self.transactionsVM = transactionsVM
        self.categoriesVM = categoriesVM
        self.tagsVM = tagsVM
        self.transaction = transaction
        self.currency = currency

        _amount = State(initialValue: String(format: "%.2f", CurrencyFormatter.toDecimal(cents: transaction.amount)))
        _description = State(initialValue: transaction.description)
        _transactionType = State(initialValue: TransactionType(rawValue: transaction.transactionType) ?? .expense)
        _selectedCategoryId = State(initialValue: transaction.categoryId)
        _selectedTagIds = State(initialValue: [])
        _originalTagIds = State(initialValue: [])
        _date = State(initialValue: DateUtils.parse(transaction.date) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type selector
                Section {
                    Picker(L10n.tr("transactions.type"), selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                // Amount & details
                Section(L10n.tr("transactions.details")) {
                    HStack {
                        Text(CurrencyFormatter.symbol(for: currency))
                            .foregroundColor(.secondary)
                            .font(.title3)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                    }

                    TextField(L10n.tr("transactions.description"), text: $description)
                        .textInputAutocapitalization(.sentences)

                    DatePicker(
                        L10n.tr("transactions.date"),
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // Category picker
                Section(L10n.tr("transactions.category")) {
                    if categoriesVM.categories.isEmpty {
                        Text(L10n.tr("transactions.noCategoriesAvailable"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(categoriesVM.categories) { category in
                            Button {
                                selectedCategoryId = category.id
                            } label: {
                                HStack(spacing: 12) {
                                    Text(category.icon)
                                        .font(.title2)
                                    Text(category.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedCategoryId == category.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }

                // Tags
                TransactionTagPicker(
                    tagsVM: tagsVM,
                    transactionId: transaction.id,
                    selectedTagIds: $selectedTagIds
                )

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        transactionsVM.deleteTransaction(transactionId: transaction.id)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(L10n.tr("transactions.deleteTransaction"))
                        }
                    }
                }
            }
            .navigationTitle(L10n.tr("transactions.editTransaction"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Load existing tags for this transaction
                let existingTags = tagsVM.getTransactionTags(transactionId: transaction.id)
                let ids = Set(existingTags.map(\.id))
                selectedTagIds = ids
                originalTagIds = ids
                if tagsVM.tags.isEmpty {
                    tagsVM.loadTags()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("common.save")) {
                        guard let cents = CurrencyFormatter.toCents(amount) else { return }
                        transactionsVM.editTransaction(
                            transactionId: transaction.id,
                            amount: cents,
                            type: transactionType,
                            description: description.trimmingCharacters(in: .whitespaces),
                            categoryId: selectedCategoryId,
                            date: date
                        )
                        // Apply tag changes (diff)
                        let added = selectedTagIds.subtracting(originalTagIds)
                        let removed = originalTagIds.subtracting(selectedTagIds)
                        for tagId in added {
                            tagsVM.toggleTag(tagId: tagId, on: transaction.id, isAdding: true)
                        }
                        for tagId in removed {
                            tagsVM.toggleTag(tagId: tagId, on: transaction.id, isAdding: false)
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isValid: Bool {
        !amount.isEmpty &&
        CurrencyFormatter.toCents(amount) != nil &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedCategoryId.isEmpty
    }
}
