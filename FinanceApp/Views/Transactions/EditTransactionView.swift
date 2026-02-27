import SwiftUI

struct EditTransactionView: View {
    @ObservedObject var transactionsVM: TransactionsViewModel
    @ObservedObject var categoriesVM: CategoriesViewModel
    let transaction: FinanceTransaction
    let currency: String

    @Environment(\.dismiss) private var dismiss

    @State private var amount: String
    @State private var description: String
    @State private var transactionType: TransactionType
    @State private var selectedCategoryId: String
    @State private var date: Date

    init(
        transactionsVM: TransactionsViewModel,
        categoriesVM: CategoriesViewModel,
        transaction: FinanceTransaction,
        currency: String
    ) {
        self.transactionsVM = transactionsVM
        self.categoriesVM = categoriesVM
        self.transaction = transaction
        self.currency = currency

        _amount = State(initialValue: String(format: "%.2f", CurrencyFormatter.toDecimal(cents: transaction.amount)))
        _description = State(initialValue: transaction.description)
        _transactionType = State(initialValue: TransactionType(rawValue: transaction.transactionType) ?? .expense)
        _selectedCategoryId = State(initialValue: transaction.categoryId)
        _date = State(initialValue: DateUtils.parse(transaction.date) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type selector
                Section {
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                // Amount & details
                Section("Details") {
                    HStack {
                        Text(CurrencyFormatter.symbol(for: currency))
                            .foregroundColor(.secondary)
                            .font(.title3)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                    }

                    TextField("Description", text: $description)
                        .textInputAutocapitalization(.sentences)

                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // Category picker
                Section("Category") {
                    if categoriesVM.categories.isEmpty {
                        Text("No categories available")
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

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        transactionsVM.deleteTransaction(transactionId: transaction.id)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Transaction")
                        }
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let cents = CurrencyFormatter.toCents(amount) else { return }
                        transactionsVM.editTransaction(
                            transactionId: transaction.id,
                            amount: cents,
                            type: transactionType,
                            description: description.trimmingCharacters(in: .whitespaces),
                            categoryId: selectedCategoryId,
                            date: date
                        )
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
