import XCTest
@testable import PlantCareAI

final class RegisterWateringTests: XCTestCase {
    func event(_ date: Date, zone: String = "Europe/Madrid", note: String? = nil) -> CareEvent {
        CareEvent(id: UUID(), plantID: UUID(), kind: .watering, occurredAt: date, note: note,
                  createdAt: Date(timeIntervalSince1970: 1_800_000_000), timeZoneIdentifier: zone)
    }

    func testGregorianDaysDSTWinterSummerAndOmittedCivilDay() throws {
        let madrid = try RegisterWatering.zone("Europe/Madrid")
        let winter = try RegisterWatering.startOfDay(year: 2026, month: 1, day: 12, zone: madrid)
        let summer = try RegisterWatering.startOfDay(year: 2026, month: 7, day: 12, zone: madrid)
        XCTAssertEqual(madrid.secondsFromGMT(for: winter), 3600)
        XCTAssertEqual(madrid.secondsFromGMT(for: summer), 7200)
        let day = try RegisterWatering.startOfDay(year: 2026, month: 3, day: 30, zone: madrid)
        let yesterday = RegisterWatering.calendar(in: madrid).date(byAdding: .day, value: -1, to: day)!
        XCTAssertEqual(day.timeIntervalSince(yesterday), 23 * 3600)
        XCTAssertNoThrow(try RegisterWatering.validateStructure(event(yesterday)))
        XCTAssertThrowsError(try RegisterWatering.startOfDay(year: 2011, month: 12, day: 30, zone: try RegisterWatering.zone("Pacific/Apia")))
        let havana = try RegisterWatering.zone("America/Havana")
        let midnightDST = try RegisterWatering.startOfDay(year: 2026, month: 3, day: 8, zone: havana)
        XCTAssertEqual(RegisterWatering.calendar(in: havana).component(.hour, from: midnightDST), 1)
    }

    func testRejectsFutureNonfiniteInvalidZonesAndNonStartOfDayButAllowsPreEnrollment() throws {
        let date = try RegisterWatering.startOfDay(year: 1900, month: 1, day: 1, zone: try RegisterWatering.zone("Europe/Madrid"))
        XCTAssertNoThrow(try RegisterWatering.validateInsertion(event(date), now: Date()))
        XCTAssertThrowsError(try RegisterWatering.validateInsertion(event(date), now: date.addingTimeInterval(-1)))
        XCTAssertThrowsError(try RegisterWatering.validateStructure(event(Date(timeIntervalSince1970: .infinity))))
        XCTAssertThrowsError(try RegisterWatering.validateStructure(event(date.addingTimeInterval(1))))
        for zone in ["", "CET", "GMT", "UTC", "EST", "PST", "GMT+0200", "Etc/GMT", "Etc/GMT0", "Etc/GMT+2", "Invalid/Unknown"] {
            XCTAssertThrowsError(try RegisterWatering.zone(zone))
        }
    }

    func testNoteNormalizationPreservesInteriorUnicodeAndUnlimitedLength() {
        let note = "🌿 Línea uno\n\n  Línea dos " + String(repeating: "é", count: 5000)
        XCTAssertEqual(RegisterWatering.normalized(event(Date(), note: " \n" + note + " \n")).note, note)
        XCTAssertNil(RegisterWatering.normalized(event(Date(), note: " \n\t")).note)
        let decomposed = "e\u{301}\n  🌿"
        let normalized = RegisterWatering.normalized(event(Date(), note: " \n" + decomposed + " \n"))
        XCTAssertEqual(Array(normalized.note!.utf8), Array(decomposed.utf8))
        XCTAssertFalse(CareEvent.identicalNotes("é", "e\u{301}"))
    }
}
