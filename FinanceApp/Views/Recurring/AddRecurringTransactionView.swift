import SwiftUI

struct AddRecurringTransactionView: View {
    @ObservedObject var viewModel: RecurringTransactionsViewModel
    @ObservedObject var categoriesVM: CategoriesViewModel
    let currency: String

    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var description = ""
    @State private var transactionType: TransactionType = .expense
    @State private var selectedCategoryId = ""
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                // Type selector
                Section {
                    Picker(L10n.tr("transactions.type"), selection: $transactionType) {
                        ForEach([TransactionType.expense, .income], id: \.self) { type in
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
                }

                // Category
                Section(L10n.tr("categories.category")) {
                    if categoriesVM.categories.isEmpty {
                        Text(L10n.tr("categories.noCategories"))
                            .foregroundColor(.secondary)
                    } else {
                        Picker(L10n.tr("categories.category"), selection: $selectedCategoryId) {
                            Text(L10n.tr("common.select")).tag("")
                            ForEach(categoriesVM.categories) { cat in
                                Text("\(cat.icon) \(cat.name)").tag(cat.id)
                            }
                        }
                    }
                }

                // Frequency
                Section(L10n.tr("recurring.recurrence")) {
                    Picker(L10n.tr("recurring.frequency"), selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    DatePicker(L10n.tr("recurring.startDate"), selection: $startDate, displayedComponents: .date)

                    Toggle(L10n.tr("recurring.hasEndDate"), isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker(L10n.tr("recurring.endDate"), selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(L10n.tr("recurring.newRecurring"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("common.save")) { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var isValid: Bool {
        !amount.isEmpty &&
        CurrencyFormatter.toCents(amount) != nil &&
        !description.isEmpty &&
        !selectedCategoryId.isEmpty
    }

    private func save() {
        guard let cents = CurrencyFormatter.toCents(amount) else { return }

        viewModel.create(
            categoryId: selectedCategoryId,
            amount: cents,
            transactionType: transactionType.rawValue,
            description: description,
            frequency: frequency.rawValue,
            startDate: DateUtils.toRFC3339(startDate),
            endDate: hasEndDate ? DateUtils.toRFC3339(endDate) : nil
        )
        dismiss()
    }
}
