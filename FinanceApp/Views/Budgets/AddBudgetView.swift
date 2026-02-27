import SwiftUI

struct AddBudgetView: View {
    @ObservedObject var viewModel: BudgetsViewModel
    @ObservedObject var categoriesVM: CategoriesViewModel
    let currency: String

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amount = ""
    @State private var period: BudgetPeriod = .monthly
    @State private var startDate = Date()
    @State private var isAccountWide = true
    @State private var selectedCategoryId = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Info") {
                    TextField("Budget Name", text: $name)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text(CurrencyFormatter.symbol(for: currency))
                            .foregroundColor(.secondary)
                            .font(.title3)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                    }
                }

                Section("Period") {
                    Picker("Period", selection: $period) {
                        ForEach(BudgetPeriod.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section("Scope") {
                    Toggle("All Categories", isOn: $isAccountWide)

                    if !isAccountWide {
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
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Budget Alerts", systemImage: "bell.badge")
                            .font(.subheadline.weight(.medium))
                        Text("You'll be alerted at 80%, 100%, and 120% of your budget limit.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.orange.opacity(0.06))
                }
            }
            .navigationTitle("New Budget")
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
        !name.isEmpty &&
        !amount.isEmpty &&
        CurrencyFormatter.toCents(amount) != nil &&
        (isAccountWide || !selectedCategoryId.isEmpty)
    }

    private func save() {
        guard let cents = CurrencyFormatter.toCents(amount) else { return }

        viewModel.create(
            categoryId: isAccountWide ? nil : selectedCategoryId,
            name: name,
            amount: cents,
            period: period.rawValue,
            startDate: DateUtils.toRFC3339(startDate)
        )
        dismiss()
    }
}
