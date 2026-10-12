import XCTest
@testable import PlantCareAI

final class PlantTimelineDateFormatterTests: XCTestCase {
    private let zone = TimeZone(identifier: "Etc/UTC")!
    private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }
    private func care(_ id: Int, _ occurred: String, _ created: String, origin: String = "Africa/Abidjan") -> PlantTimelineEntry {
        .care(CareEvent(id: PlantTimelineFixtureLoad.id(id), plantID: StorageTestFixture.plant(1).id, kind: .watering,
                       occurredAt: date(occurred), note: nil, createdAt: date(created), timeZoneIdentifier: origin))
    }
    func testVisibleDayNotInstantOrdersCreationThenDiscriminatedKeyWithoutOccurredTie() throws {
        let older = care(1, "2026-10-11T23:00:00Z", "2026-10-12T20:00:00Z", origin: "Europe/London")
        let newer = care(2, "2026-10-11T00:00:00Z", "2026-10-12T21:00:00Z")
        let tie = care(3, "2026-10-11T22:00:00Z", "2026-10-12T21:00:00Z", origin: "Europe/Madrid")
        let photo = PlantTimelineEntry.additional(PlantPhoto(id: PlantTimelineFixtureLoad.id(2), plantID: older.plantID,
            occurredAt: date("2026-10-11T01:00:00Z"), createdAt: newer.createdAt, timeZoneIdentifier: "Atlantic/Cape_Verde", width: 640, height: 480))
        let humanDate = care(4, "2026-10-10T00:00:00Z", "2026-10-11T22:00:00Z")
        let input = [older, newer, tie, photo, humanDate]
        // These different instants are genuine origin-day starts, not invented observation hours.
        for entry in input {
            switch entry {
            case .care(let event): try RegisterCareEvent.validateStructure(event)
            case .additional(let photo): try AddPlantPhoto.validateStructure(photo)
            case .initial: break
            }
        }
        let groups = PlantTimelineDateFormatter.groups(entries: input, now: date("2026-10-12T12:00:00Z"), timeZone: zone)
        XCTAssertEqual(groups.map(\.id), ["2026-10-11", "2026-10-10"])
        XCTAssertEqual(groups[0].title, "Ayer")
        XCTAssertEqual(groups[0].entries, [photo, newer, tie, older])
        XCTAssertEqual(groups[1].entries, [humanDate])
        XCTAssertEqual(groups, PlantTimelineDateFormatter.groups(entries: input.reversed(), now: date("2026-10-12T12:00:00Z"), timeZone: zone))
    }
    func testZoneMergeSeparatesAndReversesFinalOrderPreservingIdentities() {
        let a = care(1, "2026-10-11T23:00:00Z", "2026-10-12T02:00:00Z", origin: "Europe/London")
        let b = care(2, "2026-10-12T00:00:00Z", "2026-10-12T01:00:00Z")
        let now = date("2026-10-12T12:00:00Z")
        let split = PlantTimelineDateFormatter.groups(entries: [a, b], now: now, timeZone: zone)
        XCTAssertEqual(split.flatMap(\.entries), [b, a]); XCTAssertEqual(split.count, 2)
        let merged = PlantTimelineDateFormatter.groups(entries: [a, b], now: now, timeZone: TimeZone(identifier: "Europe/Madrid")!)
        XCTAssertEqual(merged.count, 1); XCTAssertEqual(merged[0].entries, [a, b]); XCTAssertEqual(merged[0].title, "Hoy")
        XCTAssertEqual(Set(split.flatMap(\.entries).map(\.id)), Set(merged.flatMap(\.entries).map(\.id)))
    }
    func testYesterdayCalendarDSTClockBackwardAndFullSpanishYear() {
        let entry = care(1, "2026-03-29T00:00:00Z", "2026-03-30T00:00:00Z")
        let madrid = TimeZone(identifier: "Europe/Madrid")!
        let now = date("2026-03-29T22:30:00Z") // March 30 after a 23-hour day.
        XCTAssertEqual(PlantTimelineDateFormatter.groups(entries: [entry], now: now, timeZone: madrid)[0].title, "Ayer")
        let backward = PlantTimelineDateFormatter.groups(entries: [entry], now: date("2026-03-28T12:00:00Z"), timeZone: madrid)
        XCTAssertEqual(backward[0].entries, [entry]); XCTAssertEqual(backward[0].title, "29 de marzo de 2026")
    }
}
