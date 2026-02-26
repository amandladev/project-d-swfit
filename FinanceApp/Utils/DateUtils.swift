import Foundation

struct DateUtils {

    // MARK: - Formatters

    private static let rfc3339WithFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let rfc3339: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let displayDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    // MARK: - Parsing

    /// Parses an RFC 3339 date string (with or without fractional seconds).
    static func parse(_ string: String) -> Date? {
        rfc3339WithFrac.date(from: string) ?? rfc3339.date(from: string)
    }

    // MARK: - Formatting

    /// Converts a Date to RFC 3339 string for sending to the backend.
    static func toRFC3339(_ date: Date) -> String {
        rfc3339.string(from: date)
    }

    /// Human-readable date+time from an RFC 3339 string.
    static func displayString(_ dateString: String) -> String {
        guard let date = parse(dateString) else { return dateString }
        return displayDateTimeFormatter.string(from: date)
    }

    /// Human-readable date-only from an RFC 3339 string.
    static func dateOnlyString(_ dateString: String) -> String {
        guard let date = parse(dateString) else { return dateString }
        return displayDateFormatter.string(from: date)
    }

    /// Month + Year from an RFC 3339 string (e.g. "February 2026").
    static func monthYearString(_ dateString: String) -> String {
        guard let date = parse(dateString) else { return dateString }
        return monthYearFormatter.string(from: date)
    }

    /// Relative time description (e.g. "2 hours ago", "Yesterday").
    static func relativeString(_ dateString: String) -> String {
        guard let date = parse(dateString) else { return dateString }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
