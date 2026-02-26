import Foundation

struct CurrencyFormatter {

    /// Formats amount in cents to a localized currency string.
    /// Example: 1050, "USD" → "$10.50"
    static func format(cents: Int64, currency: String = "USD") -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }

    /// Parses a decimal string to cents.
    /// Example: "10.50" → 1050
    static func toCents(_ string: String) -> Int64? {
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned) else { return nil }
        return Int64((amount * 100).rounded())
    }

    /// Converts cents to a decimal value.
    /// Example: 1050 → 10.50
    static func toDecimal(cents: Int64) -> Double {
        Double(cents) / 100.0
    }

    /// Returns the currency symbol for a given currency code.
    static func symbol(for currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? currencyCode
    }
}
