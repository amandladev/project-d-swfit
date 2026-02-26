import SwiftUI

/// Reusable component that formats and displays a cents amount as a currency string.
struct CurrencyText: View {
    let cents: Int64
    let currency: String

    init(cents: Int64, currency: String = "USD") {
        self.cents = cents
        self.currency = currency
    }

    var body: some View {
        Text(CurrencyFormatter.format(cents: cents, currency: currency))
    }
}
