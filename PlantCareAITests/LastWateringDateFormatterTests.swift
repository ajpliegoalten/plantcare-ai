import XCTest
@testable import PlantCareAI

final class LastWateringDateFormatterTests: XCTestCase {
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }

    func testExactSpanishTodayPastAndYearWithGregorianCurrentZone() {
        let utc = TimeZone(secondsFromGMT: 0)!, now = date("2026-10-12T12:00:00Z")
        XCTAssertEqual(LastWateringDateFormatter.string(now, now: now, timeZone: utc, compact: true), "hoy")
        XCTAssertEqual(LastWateringDateFormatter.string(now, now: now, timeZone: utc, compact: false), "Hoy, 12 oct 2026")
        XCTAssertEqual(LastWateringDateFormatter.string(date("2026-10-08T10:00:00Z"), now: now, timeZone: utc, compact: true), "8 oct 2026")
        XCTAssertEqual(LastWateringDateFormatter.string(date("2025-01-02T10:00:00Z"), now: now, timeZone: utc, compact: false), "2 ene 2025")
    }

    func testDayNot24HoursTravelAndBackwardClockKeepAbsoluteEvent() {
        let event = date("2026-10-12T00:30:00Z"), now = date("2026-10-12T23:30:00Z")
        let madrid = TimeZone(identifier: "Europe/Madrid")!, utc = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(LastWateringDateFormatter.string(event, now: now, timeZone: utc, compact: true), "hoy")
        XCTAssertEqual(LastWateringDateFormatter.string(event, now: now, timeZone: madrid, compact: true), "12 oct 2026")
        XCTAssertEqual(LastWateringDateFormatter.string(event, now: date("2026-10-11T00:00:00Z"), timeZone: utc, compact: true), "12 oct 2026")
    }

    func testNextGregorianDayAcrossDSTIsNotFixed24Hours() {
        let zone = TimeZone(identifier: "Europe/Madrid")!
        let start = date("2026-03-28T23:00:00Z")
        XCTAssertEqual(LastWateringDateFormatter.nextDay(after: start, timeZone: zone), date("2026-03-29T22:00:00Z"))
        XCTAssertEqual(LastWateringDateFormatter.nextDay(after: date("2026-10-24T22:00:00Z"), timeZone: zone), date("2026-10-25T23:00:00Z"))
    }
}
