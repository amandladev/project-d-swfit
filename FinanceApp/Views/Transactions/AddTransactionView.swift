import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var transactionsVM: TransactionsViewModel
    @ObservedObject var categoriesVM: CategoriesViewModel
    let currency: String

    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var description = ""
    @State private var transactionType: TransactionType = .expense
    @State private var selectedCategoryId = ""
    @State private var date = Date()

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
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No categories available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Go to the Categories tab to create one first.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(categoriesVM.categories) { category in
                            CategorySelectionRow(
                                category: category,
                                isSelected: selectedCategoryId == category.id
                            ) {
                                selectedCategoryId = category.id
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let cents = CurrencyFormatter.toCents(amount) else { return }
                        transactionsVM.createTransaction(
                            categoryId: selectedCategoryId,
                            amount: cents,
                            type: transactionType,
                            description: description.trimmingCharacters(in: .whitespaces),
                            date: date
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if categoriesVM.categories.isEmpty {
                    categoriesVM.loadCategories()
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

// MARK: - Category Selection Row

private struct CategorySelectionRow: View {
    let category: FinanceCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(category.icon)
                    .font(.title2)
                Text(category.name)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
