import Foundation

/// Seeds default categories for a new user.
struct DefaultCategories {

    struct Seed {
        let name: String
        let icon: String
    }

    static let all: [Seed] = [
        Seed(name: "Food & Dining",    icon: "🍔"),
        Seed(name: "Groceries",        icon: "🛒"),
        Seed(name: "Transportation",   icon: "🚗"),
        Seed(name: "Housing & Rent",   icon: "🏠"),
        Seed(name: "Utilities",        icon: "⚡"),
        Seed(name: "Entertainment",    icon: "🎬"),
        Seed(name: "Shopping",         icon: "👕"),
        Seed(name: "Health",           icon: "💊"),
        Seed(name: "Education",        icon: "📚"),
        Seed(name: "Travel",           icon: "✈️"),
        Seed(name: "Subscriptions",    icon: "📱"),
        Seed(name: "Fitness",          icon: "🏋️"),
        Seed(name: "Coffee",           icon: "☕"),
        Seed(name: "Gifts",            icon: "🎁"),
        Seed(name: "Salary",           icon: "💼"),
        Seed(name: "Freelance",        icon: "💻"),
        Seed(name: "Investments",      icon: "📈"),
        Seed(name: "Other",            icon: "💰"),
    ]

    /// Creates all default categories for the given user. Ignores individual failures.
    static func seedIfNeeded(userId: String) {
        // Check if user already has categories
        let existing = try? FinanceBridge.listCategories(userId: userId)
        guard existing == nil || existing!.isEmpty else { return }

        for seed in all {
            _ = try? FinanceBridge.createCategory(userId: userId, name: seed.name, icon: seed.icon)
        }
    }
}
