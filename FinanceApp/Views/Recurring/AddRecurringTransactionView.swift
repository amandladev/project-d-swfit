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
                    Picker("Type", selection: $transactionType) {
                        ForEach([TransactionType.expense, .income], id: \.self) { type in
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
                }

                // Category
                Section("Category") {
                    if categoriesVM.categories.isEmpty {
                        Text("No categories available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategoryId) {
                            Text("Select").tag("")
                            ForEach(categoriesVM.categories) { cat in
                                Text("\(cat.icon) \(cat.name)").tag(cat.id)
                            }
                        }
                    }
                }

                // Frequency
                Section("Recurrence") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    Toggle("Has End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
