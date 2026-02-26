import SwiftUI

struct AddAccountView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var currency = "USD"

    private let currencies = ["USD", "EUR", "GBP", "MXN", "CAD", "JPY", "BRL", "ARS"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Currency", selection: $currency) {
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
                    Text("Examples: Checking, Savings, Cash, Credit Card")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
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
        case "CAD": return "🇨🇦"
        case "JPY": return "🇯🇵"
        case "BRL": return "🇧🇷"
        case "ARS": return "🇦🇷"
        default:    return "💰"
        }
    }
}
