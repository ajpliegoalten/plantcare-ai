import XCTest
@testable import PlantCareAI

final class BuildPlantAnalysisContextTests: XCTestCase {
    static let plantID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let sheet = CareSheet(light: "Luz", watering: "Riego", humidity: "Humedad", temperature: "Temperatura", substrate: "Sustrato", fertilizer: "Abonado")
    static func plant(id: UUID = plantID, location: String? = "Interior", sheet: CareSheet = sheet) -> Plant {
        Plant(id: id, name: "NO ENVIAR NOMBRE", confirmedSpecies: "Ficus", createdAt: date(0), location: location, careSheet: sheet)
    }
    static func date(_ day: Int) -> Date { Date(timeIntervalSince1970: Double(day) * 86400) }
    static let content = PlantPhotoAnalysisContent(outcome: .analysis, observations: ["Observación"], possibleCauses: [], checks: ["Comprobar"])
    func event(_ day: Int, id: UUID = UUID(), plantID: UUID = plantID, note: String? = nil) -> CareEvent {
        .init(id: id, plantID: plantID, kind: .watering, occurredAt: Self.date(day), note: note, createdAt: Self.date(day + 1), timeZoneIdentifier: "Africa/Abidjan")
    }
    func build(day: Int = 100, care: [CareEvent] = [], accepted: [AcceptedPlantPhotoAnalysis] = [], plant: Plant = plant(), zone: TimeZone = TimeZone(secondsFromGMT: 0)!) throws -> PlantAnalysisContext {
        try BuildPlantAnalysisContext().execute(plant: plant,
            photo: .init(id: .additional(UUID()), date: Self.date(day), createdAt: Self.date(200)),
            care: care, accepted: accepted, queriedAt: Self.date(300), timeZone: zone)
    }
    func testFiltersBeforeLimitsStrictEarlierDayOwnPlantAndNinetyDayWindow() throws {
        let values = [event(100), event(101), event(9), event(10), event(99), event(98, plantID: UUID())]
        let context = try build(care: values)
        XCTAssertEqual(context.careEvents.map(\.date), ["1970-04-10", "1970-01-11"])
        XCTAssertEqual(context.omittedCareEvents, 1)
        XCTAssertEqual(try build(day: 0, care: [event(-1)]).careEvents.count, 1)
    }
    func testTwentyLimitStableTiesNotePrefixUnicodeAndNoMutation() throws {
        let note = String(repeating: "x", count: 501)
        let records = (0..<25).map { event(99 - $0, note: note) }
        let context = try build(care: records.reversed())
        XCTAssertEqual(context.careEvents.count, 20); XCTAssertEqual(context.omittedCareEvents, 5)
        XCTAssertEqual(context.careEvents[0].note?.count, 500); XCTAssertTrue(context.careEvents[0].noteWasShortened)
        XCTAssertEqual(records[0].note, note)
        XCTAssertEqual(try context.encoded(), try build(care: records).encoded())
        let unicode = String(repeating: "🌱", count: 501)
        let unicodeContext = try build(care: [event(99, note: unicode)])
        XCTAssertEqual(unicodeContext.careEvents[0].note, String(repeating: "🌱", count: 500))
    }
    func testAcceptedTextsUseSourcePhotoDateExcludeOwnSameDayFutureAndOtherPlant() throws {
        let current = PlantPhotoDescriptor(id: .additional(UUID()), date: Self.date(100), createdAt: Self.date(200))
        let values = [90, 99, 100, 101, -200].map { day in
            AcceptedPlantPhotoAnalysis(plantID: Self.plantID, identity: .additional(UUID()), photoDate: Self.date(day), content: Self.content)
        } + [.init(plantID: UUID(), identity: .additional(UUID()), photoDate: Self.date(98), content: Self.content),
             .init(plantID: Self.plantID, identity: current.id, photoDate: Self.date(80), content: Self.content)]
        let context = try BuildPlantAnalysisContext().execute(plant: Self.plant(), photo: current, care: [], accepted: values,
            queriedAt: Self.date(300), timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(context.previousAcceptedInterpretations.map(\.photoDate), ["1970-04-10", "1970-04-01", "1969-06-15"])
        let text = String(decoding: try context.encoded(), as: UTF8.self)
        XCTAssertFalse(text.contains(Self.plantID.uuidString)); XCTAssertFalse(text.contains("NO ENVIAR NOMBRE"))
        XCTAssertFalse(text.contains("image_url")); XCTAssertEqual(context.queryDate, "1970-10-28")
    }
    func testFiveAcceptedBlocksBudgetDropsOldestAnalysisBeforeCareWithoutTruncation() throws {
        let long = PlantPhotoAnalysisContent(outcome: .analysis, observations: [String(repeating: "🌱", count: 1000)], possibleCauses: [], checks: [String(repeating: "X", count: 1000)])
        let values = (0..<7).map { AcceptedPlantPhotoAnalysis(plantID: Self.plantID, identity: .additional(UUID()), photoDate: Self.date(99 - $0), content: long) }
        let context = try build(care: [event(99)], accepted: values)
        XCTAssertLessThanOrEqual(try context.encoded().count, 16384)
        XCTAssertEqual(context.careEvents.count, 1); XCTAssertEqual(context.previousAcceptedInterpretations.count, 3)
        XCTAssertEqual(context.omittedAcceptedInterpretations, 4)
        XCTAssertEqual(context.previousAcceptedInterpretations.first?.interpretation, long)
    }
    func testOversizeBaseFailsClosedAndCareBudgetDropsOldestDeterministically() throws {
        XCTAssertThrowsError(try build(plant: Self.plant(location: String(repeating: "x", count: 17000))))
        let context = try build(care: (0..<20).map { event(99 - $0, note: String(repeating: "🌱", count: 500)) })
        XCTAssertLessThanOrEqual(try context.encoded().count, 16384); XCTAssertLessThan(context.careEvents.count, 20)
        XCTAssertEqual(context.careEvents.first?.date, "1970-04-10")
        XCTAssertEqual(context.omittedCareEvents, 20 - context.careEvents.count)
    }
    func testReferenceZoneDSTStrictDayAndQueryIndependentOfPhotoCutoff() throws {
        let zone = TimeZone(identifier: "America/New_York")!
        var cal = Calendar(identifier: .gregorian); cal.timeZone = zone
        let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 9))!
        let prior = cal.date(byAdding: .day, value: -1, to: date)!
        let events = [CareEvent(id: UUID(), plantID: Self.plantID, kind: .other, occurredAt: prior, note: nil, createdAt: date, timeZoneIdentifier: zone.identifier)]
        let context = try BuildPlantAnalysisContext().execute(plant: Self.plant(), photo: .init(id: .initial(Self.plantID), date: date, createdAt: date),
            care: events, accepted: [], queriedAt: date.addingTimeInterval(1000000), timeZone: zone)
        XCTAssertEqual(context.careEvents.first?.date, "2026-03-08"); XCTAssertEqual(context.photoDate, "2026-03-09")
        XCTAssertEqual(context.referenceTimeZone, zone.identifier)
    }
    func testAcceptedStableIdentityTieAndInvalidIncludedBlockFailsClosed() throws {
        let low = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, high = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let one = PlantPhotoAnalysisContent(outcome: .analysis, observations: ["Primero"], possibleCauses: [], checks: ["Comprobar"])
        let two = PlantPhotoAnalysisContent(outcome: .analysis, observations: ["Segundo"], possibleCauses: [], checks: ["Comprobar"])
        let values = [AcceptedPlantPhotoAnalysis(plantID: Self.plantID, identity: .additional(high), photoDate: Self.date(99), content: two),
                      .init(plantID: Self.plantID, identity: .additional(low), photoDate: Self.date(99), content: one)]
        XCTAssertEqual(try build(accepted: values).previousAcceptedInterpretations.map(\.interpretation.observations), [["Primero"], ["Segundo"]])
        let invalid = PlantPhotoAnalysisContent(outcome: .analysis, observations: [" "], possibleCauses: [], checks: ["Comprobar"])
        XCTAssertThrowsError(try build(accepted: [.init(plantID: Self.plantID, identity: .additional(low), photoDate: Self.date(99), content: invalid)]))
    }
}
