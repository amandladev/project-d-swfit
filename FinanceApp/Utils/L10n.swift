import Foundation

/// Lightweight localization helper.
/// Usage: `L10n.tr("common.cancel")`  or  `L10n.tr("budgets.spent %@", formatted)`
enum L10n {
    /// Look up a localized string by key, with optional format arguments.
    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return args.isEmpty ? format : String(format: format, arguments: args)
    }
}
