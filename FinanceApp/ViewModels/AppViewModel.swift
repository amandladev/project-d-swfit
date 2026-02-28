import Foundation
import SwiftUI
import WidgetKit

// Key stored outside the actor so Task.detached can access it
private let kUserIdKey = "finance_current_user_id"
private let kAppGroupId = "group.com.sergiofinance.FinanceApp"

/// Root view model: initializes the database and manages the current user session.
@MainActor
class AppViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var error: String?
    @Published var needsOnboarding = false

    // MARK: - Initialization

    func initialize() {
        isLoading = true
        error = nil

        let dbPath = Self.databasePath()
        let savedUserId = UserDefaults.standard.string(forKey: kUserIdKey)
            ?? UserDefaults(suiteName: kAppGroupId)?.string(forKey: kUserIdKey)

        Task.detached {
            do {
                // 1. Initialize the database
                try FinanceBridge.initDatabase(path: dbPath)

                // 2. Seed bundled exchange rates (idempotent)
                try? FinanceBridge.seedExchangeRates()

                // 3. Fetch fresh exchange rates from API (await so rates are ready before dashboard)
                await ExchangeRateService.fetchAndUpdateRates()

                // 4. Verify PEN→USD conversion works and write to temp file for debugging
                var debugLog = ""

                // Raw FFI call to see exact JSON response
                let rawPtr = convert_currency(100, "PEN", "USD")
                if let rawPtr = rawPtr {
                    let rawJson = String(cString: rawPtr)
                    debugLog += "RAW convert_currency JSON:\n\(rawJson)\n\n"
                    free_string(rawPtr)
                } else {
                    debugLog += "RAW convert_currency returned NULL\n\n"
                }

                do {
                    let test = try FinanceBridge.convertCurrency(amountCents: 100, from: "PEN", to: "USD")
                    debugLog += "PEN→USD OK: 100 PEN cents → \(test.convertedAmountCents) USD cents (rate: \(test.rateUsed), source: \(test.source))\n"
                } catch {
                    debugLog += "PEN→USD FAILED: \(error)\n"
                }

                // Also test listing rates from PEN
                do {
                    let rates = try FinanceBridge.listExchangeRates(from: "PEN")
                    debugLog += "PEN rates count: \(rates.count)\n"
                    for r in rates {
                        debugLog += "  PEN→\(r.toCurrency) = \(r.rate) (\(r.source))\n"
                    }
                } catch {
                    debugLog += "listExchangeRates(PEN) FAILED: \(error)\n"
                }

                // Raw list_exchange_rates JSON
                let rawListPtr = list_exchange_rates("PEN")
                if let rawListPtr = rawListPtr {
                    let rawJson = String(cString: rawListPtr)
                    debugLog += "\nRAW list_exchange_rates JSON:\n\(rawJson)\n"
                    free_string(rawListPtr)
                }

                // Raw get_rate_freshness JSON
                let rawFreshPtr = get_rate_freshness("PEN", "USD")
                if let rawFreshPtr = rawFreshPtr {
                    let rawJson = String(cString: rawFreshPtr)
                    debugLog += "\nRAW get_rate_freshness JSON:\n\(rawJson)\n"
                    free_string(rawFreshPtr)
                }

                // Write debug log to tmp
                let tmpPath = NSTemporaryDirectory() + "finance_debug.txt"
                try? debugLog.write(toFile: tmpPath, atomically: true, encoding: .utf8)
                NSLog("Debug log written to: %@", tmpPath)

                // 2. Try to load saved user
                if let userId = savedUserId {
                    do {
                        let user = try FinanceBridge.getUser(userId: userId)
                        await MainActor.run {
                            self.currentUser = user
                            self.isLoading = false
                        }
                        return
                    } catch {
                        // Saved user not found — clear and show onboarding
                        await MainActor.run {
                            UserDefaults.standard.removeObject(forKey: kUserIdKey)
                            UserDefaults(suiteName: kAppGroupId)?.removeObject(forKey: kUserIdKey)
                        }
                    }
                }

                // 3. No valid user — show onboarding
                await MainActor.run {
                    self.needsOnboarding = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - User Creation

    func createUser(name: String, email: String) {
        isLoading = true
        error = nil

        Task.detached {
            do {
                let user = try FinanceBridge.createUser(name: name, email: email)
                // Seed default categories from backend (idempotent)
                let _ = try? FinanceBridge.seedDefaultCategories(userId: user.id)
                await MainActor.run {
                    UserDefaults.standard.set(user.id, forKey: kUserIdKey)
                    UserDefaults(suiteName: kAppGroupId)?.set(user.id, forKey: kUserIdKey)
                    self.currentUser = user
                    self.needsOnboarding = false
                    self.isLoading = false
                    // Refresh widgets with new data
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Helpers

    nonisolated static func databasePath() -> String {
        // Use App Group container so widget extension can access the same database
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.sergiofinance.FinanceApp"
        ) {
            return groupURL.appendingPathComponent("finance.db").path
        }
        // Fallback to documents directory
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("finance.db").path
    }
}
