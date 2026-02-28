import Foundation

/// Fetches live exchange rates from a free API and passes them to the Rust backend.
struct ExchangeRateService {

    // Free API — no key required, supports 150+ currencies including PEN, COP, CLP, ARS, UYU
    // Uses open.er-api.com (updates daily)
    private static let baseURL = "https://open.er-api.com/v6/latest"

    // Base currencies to fetch (we build all cross-pairs from these)
    private static let baseCurrencies = ["USD", "EUR"]

    // Currencies we care about
    private static let targetCurrencies: Set<String> = [
        "USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "NZD", "CNY",
        "BRL", "MXN", "ARS", "CLP", "COP", "PEN", "UYU", "INR", "KRW"
    ]

    /// Fetch rates from API and push to backend. Awaitable so callers can wait.
    static func fetchAndUpdateRates() async {
        do {
            var rateEntries: [[String: Any]] = []

            for base in baseCurrencies {
                guard let url = URL(string: "\(baseURL)/\(base)") else { continue }

                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    print("⚠️ Exchange rate API returned status \((response as? HTTPURLResponse)?.statusCode ?? -1) for \(base)")
                    continue
                }

                // API returns: { "result": "success", "base_code": "USD", "rates": { "PEN": 3.72, ... } }
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let result = json["result"] as? String, result == "success",
                      let rates = json["rates"] as? [String: Any] else {
                    print("⚠️ Exchange rate API unexpected response for \(base)")
                    continue
                }

                for (currency, value) in rates {
                    guard targetCurrencies.contains(currency), currency != base else { continue }
                    if let rate = value as? Double, rate > 0 {
                        rateEntries.append(["from": base, "to": currency, "rate": rate])
                        // Also add inverse
                        rateEntries.append(["from": currency, "to": base, "rate": 1.0 / rate])
                    }
                }
            }

            guard !rateEntries.isEmpty else {
                print("⚠️ No exchange rates fetched from API")
                return
            }

            // Log PEN rates specifically for debugging
            let penRates = rateEntries.filter { ($0["from"] as? String == "PEN") || ($0["to"] as? String == "PEN") }
            for r in penRates {
                print("💱 PEN rate: \(r["from"]!) → \(r["to"]!) = \(r["rate"]!)")
            }

            let jsonData = try JSONSerialization.data(withJSONObject: rateEntries)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try FinanceBridge.updateExchangeRates(ratesJson: jsonString)
                print("✅ Exchange rates updated: \(rateEntries.count) pairs")
            }
        } catch {
            print("⚠️ Exchange rate fetch failed: \(error.localizedDescription)")
        }
    }
}
