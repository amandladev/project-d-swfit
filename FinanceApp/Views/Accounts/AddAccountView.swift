import SwiftUI

struct AddAccountView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var currency = "USD"

    private let currencies = ["USD", "EUR", "GBP", "MXN", "PEN", "CAD", "JPY", "BRL", "ARS", "CLP", "COP"]

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.tr("accounts.accountDetails")) {
                    TextField(L10n.tr("accounts.accountName"), text: $name)
                        .textInputAutocapitalization(.words)

                    Picker(L10n.tr("accounts.currency"), selection: $currency) {
                        ForEach(currencies, id: \.self) { code in
                            HStack {
                                Text(flag(for: code))
                                Text(code)
                            }
                            .tag(code)
                        }
                    }
                }

                Section {
                    Text(L10n.tr("accounts.examples"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(L10n.tr("accounts.newAccount"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("common.create")) {
                        viewModel.createAccount(
                            name: name.trimmingCharacters(in: .whitespaces),
                            currency: currency
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func flag(for currency: String) -> String {
        switch currency {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "MXN": return "🇲🇽"
        case "PEN": return "🇵🇪"
        case "CAD": return "🇨🇦"
        case "JPY": return "🇯🇵"
        case "BRL": return "🇧🇷"
        case "ARS": return "🇦🇷"
        case "CLP": return "🇨🇱"
        case "COP": return "🇨🇴"
        default:    return "💰"
        }
    }
}
