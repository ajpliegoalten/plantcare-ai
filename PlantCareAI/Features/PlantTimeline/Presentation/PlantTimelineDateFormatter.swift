import Foundation

enum PlantTimelineDateFormatter {
    struct Group: Identifiable, Equatable {
        let id: String
        let day: Date
        let title: String
        let entries: [PlantTimelineEntry]
    }

    static func groups(entries: [PlantTimelineEntry], now: Date, timeZone: TimeZone) -> [Group] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let date = DateFormatter()
        date.locale = Locale(identifier: "es_ES"); date.calendar = calendar; date.timeZone = timeZone
        date.dateStyle = .long; date.timeStyle = .none
        let identifier = DateFormatter()
        identifier.locale = Locale(identifier: "en_US_POSIX"); identifier.calendar = calendar
        identifier.timeZone = timeZone; identifier.dateFormat = "yyyy-MM-dd"
        return Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.elementDate) })
            .keys.sorted(by: >).map { day in
                let values = entries.filter { calendar.startOfDay(for: $0.elementDate) == day }.sorted {
                    if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
                    return $0.id.stableKey < $1.id.stableKey
                }
                let title: String
                if day == today { title = String(localized: "timeline.today", defaultValue: "Hoy") }
                else if day == yesterday { title = String(localized: "timeline.yesterday", defaultValue: "Ayer") }
                else { title = date.string(from: day) }
                return Group(id: identifier.string(from: day), day: day, title: title, entries: values)
            }
    }
}
