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
                Section(L10n.tr("budgets.budgetInfo")) {
                    TextField(L10n.tr("budgets.budgetName"), text: $name)
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

                Section(L10n.tr("budgets.periodSection")) {
                    Picker(L10n.tr("budgets.periodSection"), selection: $period) {
                        ForEach(BudgetPeriod.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }

                    DatePicker(L10n.tr("budgets.startDate"), selection: $startDate, displayedComponents: .date)
                }

                Section(L10n.tr("budgets.scope")) {
                    Toggle(L10n.tr("budgets.allCategoriesToggle"), isOn: $isAccountWide)

                    if !isAccountWide {
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
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(L10n.tr("budgets.budgetAlerts"), systemImage: "bell.badge")
                            .font(.subheadline.weight(.medium))
                        Text(L10n.tr("budgets.alertsDescription"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.orange.opacity(0.06))
                }
            }
            .navigationTitle(L10n.tr("budgets.newBudget"))
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
