import XCTest
@testable import PlantCareAI

final class BuildPlantQuestionContextTests: XCTestCase {
    func build(question: String = "¿Qué revisar? 🌱", care: [CareEvent] = [], analyses: [SavedPlantPhotoAnalysis] = [], plant: Plant = BuildPlantAnalysisContextTests.plant()) throws -> PlantQuestionContext {
        try BuildPlantQuestionContext().execute(plant: plant, question: question, care: care, analyses: analyses,
            queriedAt: BuildPlantAnalysisContextTests.date(100), timeZone: TimeZone(secondsFromGMT: 0)!)
    }
    func event(_ day: Int, created: Int? = nil, plantID: UUID = BuildPlantAnalysisContextTests.plantID, note: String? = nil) -> CareEvent {
        .init(id: UUID(), plantID: plantID, kind: .watering, occurredAt: BuildPlantAnalysisContextTests.date(day), note: note,
            createdAt: BuildPlantAnalysisContextTests.date(created ?? day), timeZoneIdentifier: "Africa/Abidjan")
    }
    func analysis(_ day: Int, accepted: Int = 100, plantID: UUID = BuildPlantAnalysisContextTests.plantID, content: PlantPhotoAnalysisContent = BuildPlantAnalysisContextTests.content) -> SavedPlantPhotoAnalysis {
        .init(id: UUID(), plantID: plantID, identity: .additional(UUID()), photoDate: BuildPlantAnalysisContextTests.date(day),
            queriedAt: BuildPlantAnalysisContextTests.date(100), revision: 1, acceptedAt: BuildPlantAnalysisContextTests.date(accepted), content: content)
    }
    func testTodayInclusiveNinetyCivilDaysFutureCreationAndIsolationBeforeLimits() throws {
        let context = try build(care: [event(100), event(11), event(10), event(101), event(90, created: 101)] + (0..<30).map { event(99 - $0, plantID: UUID()) })
        XCTAssertEqual(context.careEvents.map(\.date), ["1970-04-11", "1970-01-12"])
        XCTAssertEqual(context.omittedCareEvents, 0)
        let text = String(decoding: try context.encoded(), as: UTF8.self)
        for forbidden in [BuildPlantAnalysisContextTests.plantID.uuidString, "NO ENVIAR NOMBRE", "image_url", "jpeg"] { XCTAssertFalse(text.contains(forbidden)) }
        XCTAssertEqual(context.question, "¿Qué revisar? 🌱")
    }
    func testDeterminismLimitsNoteUnicodeAndAnalysesUseOriginDate() throws {
        let records = (0..<25).map { event(100 - $0, note: String(repeating: "x", count: 501)) }
        let analyses = (0..<7).map { analysis(100 - $0) } + [analysis(101), analysis(99, accepted: 101), analysis(98, plantID: UUID())]
        let context = try build(care: records, analyses: analyses)
        XCTAssertEqual(try context.encoded(), try build(care: records.reversed(), analyses: analyses.reversed()).encoded())
        XCTAssertEqual(context.careEvents.count, 20); XCTAssertEqual(context.previousAcceptedInterpretations.count, 5)
        XCTAssertEqual(context.omittedAcceptedInterpretations, 2)
        XCTAssertEqual(context.careEvents.first?.note?.count, 500); XCTAssertEqual(context.careEvents.first?.noteWasShortened, true)
        XCTAssertEqual(records.first?.note?.count, 501); XCTAssertEqual(context.previousAcceptedInterpretations.first?.photoDate, "1970-04-11")
        XCTAssertLessThanOrEqual(try context.encoded().count, 16384)
        let unicode = try build(care: [event(100, note: String(repeating: "🌱", count: 501))])
        XCTAssertEqual(unicode.careEvents.first?.note, String(repeating: "🌱", count: 500))
    }
    func testBudgetOmitsOldestAnalysisBeforeCareAndNeverTruncatesBaseQuestion() throws {
        let content = PlantPhotoAnalysisContent(outcome: .analysis, observations: [String(repeating: "🌱", count: 1000)], possibleCauses: [], checks: [String(repeating: "x", count: 1000)])
        let context = try build(care: [event(100)], analyses: (0..<5).map { analysis(100 - $0, content: content) })
        XCTAssertEqual(context.careEvents.count, 1); XCTAssertLessThan(context.previousAcceptedInterpretations.count, 5)
        XCTAssertEqual(context.previousAcceptedInterpretations.first?.interpretation, content)
        for question in [" \n", String(repeating: "🌱", count: 2001)] { XCTAssertThrowsError(try build(question: question)) }
        XCTAssertEqual(try build(question: "  hola\n ").question, "hola")
        XCTAssertThrowsError(try build(plant: BuildPlantAnalysisContextTests.plant(location: String(repeating: "x", count: 17000))))
    }
}
