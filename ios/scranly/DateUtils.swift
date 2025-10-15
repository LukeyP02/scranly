import Foundation

extension Calendar {
    // different name to avoid confusion with Calendar.Identifier.iso8601
    static let iso8601Fixed = Calendar(identifier: .iso8601)
}

extension TimeZone {
    static let utc = TimeZone(secondsFromGMT: 0)!
}

extension DateFormatter {
    /// yyyy-MM-dd in UTC with ISO calendar
    static let isoDay: DateFormatter = {
        let df = DateFormatter()
        df.calendar = .iso8601Fixed
        df.locale   = Locale(identifier: "en_US_POSIX")
        df.timeZone = .utc
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}
