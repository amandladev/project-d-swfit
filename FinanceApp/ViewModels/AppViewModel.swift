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
                // Seed default categories for the new user
                DefaultCategories.seedIfNeeded(userId: user.id)
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
