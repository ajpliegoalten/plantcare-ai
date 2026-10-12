import XCTest
@testable import PlantCareAI

final class RegisterCareEventTests: XCTestCase {
    func event(_ date: Date, zone: String = "Europe/Madrid", note: String? = nil) -> CareEvent {
        CareEvent(id: UUID(), plantID: UUID(), kind: .watering, occurredAt: date, note: note,
                  createdAt: Date(timeIntervalSince1970: 1_800_000_000), timeZoneIdentifier: zone)
    }

    func testGregorianDaysDSTWinterSummerAndOmittedCivilDay() throws {
        let madrid = try RegisterCareEvent.zone("Europe/Madrid")
        let winter = try RegisterCareEvent.startOfDay(year: 2026, month: 1, day: 12, zone: madrid)
        let summer = try RegisterCareEvent.startOfDay(year: 2026, month: 7, day: 12, zone: madrid)
        XCTAssertEqual(madrid.secondsFromGMT(for: winter), 3600)
        XCTAssertEqual(madrid.secondsFromGMT(for: summer), 7200)
        let day = try RegisterCareEvent.startOfDay(year: 2026, month: 3, day: 30, zone: madrid)
        let yesterday = RegisterCareEvent.calendar(in: madrid).date(byAdding: .day, value: -1, to: day)!
        XCTAssertEqual(day.timeIntervalSince(yesterday), 23 * 3600)
        XCTAssertNoThrow(try RegisterCareEvent.validateStructure(event(yesterday)))
        XCTAssertThrowsError(try RegisterCareEvent.startOfDay(year: 2011, month: 12, day: 30, zone: try RegisterCareEvent.zone("Pacific/Apia")))
        let havana = try RegisterCareEvent.zone("America/Havana")
        let midnightDST = try RegisterCareEvent.startOfDay(year: 2026, month: 3, day: 8, zone: havana)
        XCTAssertEqual(RegisterCareEvent.calendar(in: havana).component(.hour, from: midnightDST), 1)
    }

    func testRejectsFutureNonfiniteInvalidZonesAndNonStartOfDayButAllowsPreEnrollment() throws {
        let date = try RegisterCareEvent.startOfDay(year: 1900, month: 1, day: 1, zone: try RegisterCareEvent.zone("Europe/Madrid"))
        XCTAssertNoThrow(try RegisterCareEvent.validateInsertion(event(date), now: Date()))
        XCTAssertThrowsError(try RegisterCareEvent.validateInsertion(event(date), now: date.addingTimeInterval(-1)))
        XCTAssertThrowsError(try RegisterCareEvent.validateStructure(event(Date(timeIntervalSince1970: .infinity))))
        XCTAssertThrowsError(try RegisterCareEvent.validateStructure(event(date.addingTimeInterval(1))))
        for zone in ["", "CET", "GMT", "UTC", "EST", "PST", "GMT+0200", "Etc/GMT", "Etc/GMT0", "Etc/GMT+2", "Invalid/Unknown"] {
            XCTAssertThrowsError(try RegisterCareEvent.zone(zone))
        }
    }

    func testNoteNormalizationPreservesInteriorUnicodeAndUnlimitedLength() {
        let note = "🌿 Línea uno\n\n  Línea dos " + String(repeating: "é", count: 5000)
        XCTAssertEqual(RegisterCareEvent.normalized(event(Date(), note: " \n" + note + " \n")).note, note)
        XCTAssertNil(RegisterCareEvent.normalized(event(Date(), note: " \n\t")).note)
        let decomposed = "e\u{301}\n  🌿"
        let normalized = RegisterCareEvent.normalized(event(Date(), note: " \n" + decomposed + " \n"))
        XCTAssertEqual(Array(normalized.note!.utf8), Array(decomposed.utf8))
        XCTAssertFalse(CareEvent.identicalNotes("é", "e\u{301}"))
    }

    func testAllStableKindsShareValidationAndNoteRules() throws {
        XCTAssertEqual(CareEvent.Kind.allCases.map(\.rawValue), ["watering", "fertilizing", "pruning", "repotting", "other"])
        let date = try RegisterCareEvent.startOfDay(year: 1900, month: 1, day: 1, zone: try RegisterCareEvent.zone("Europe/Madrid"))
        for kind in CareEvent.Kind.allCases {
            let event = CareEvent(id: UUID(), plantID: UUID(), kind: kind, occurredAt: date, note: " \n🌿\n  e\u{301} \n", createdAt: Date(), timeZoneIdentifier: "Europe/Madrid")
            let normalized = RegisterCareEvent.normalized(event)
            XCTAssertEqual(normalized.kind, kind)
            XCTAssertTrue(CareEvent.identicalNotes(normalized.note, "🌿\n  e\u{301}"))
            XCTAssertNoThrow(try RegisterCareEvent.validateInsertion(normalized, now: Date()))
            XCTAssertThrowsError(try RegisterCareEvent.validateInsertion(normalized, now: date.addingTimeInterval(-1)))
        }
    }
}
