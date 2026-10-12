import Foundation

enum LastWateringDateFormatter {
    static func calendar(in zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    static func string(_ date: Date, now: Date, timeZone: TimeZone, compact: Bool) -> String {
        let calendar = calendar(in: timeZone)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMM yyyy"
        let absolute = formatter.string(from: date).replacingOccurrences(of: ".", with: "")
        guard calendar.isDate(date, inSameDayAs: now) else { return absolute }
        return compact ? "hoy" : "Hoy, \(absolute)"
    }

    static func nextDay(after now: Date, timeZone: TimeZone) -> Date? {
        let calendar = calendar(in: timeZone)
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
    }
}
