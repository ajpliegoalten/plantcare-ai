import XCTest
@testable import PlantCareAI

final class LoadLastWateringTests: XCTestCase {
    func testMaximumOccurredAtNotCreationInsertionOrOtherKindOrPlant() async throws {
        let id = UUID(), other = UUID()
        func event(_ day: Double, _ created: Double, _ kind: CareEvent.Kind = .watering, _ plant: UUID? = nil) -> CareEvent {
            CareEvent(id: UUID(), plantID: plant ?? id, kind: kind, occurredAt: Date(timeIntervalSince1970: day),
                      note: nil, createdAt: Date(timeIntervalSince1970: created), timeZoneIdentifier: "Europe/Madrid")
        }
        let events = [event(8, 1), event(12, 10, .pruning), event(8, 3), event(20, 4, .watering, other), event(2, 100)]
        let useCase = LoadLastWatering(repository: WateringResult(events: events))
        let result = try await useCase.execute(for: id)
        XCTAssertEqual(result, Date(timeIntervalSince1970: 8))
    }

    func testSuccessfulEmptyAndOnlyOtherKindsAreNilButThrownReadStaysError() async throws {
        let id = UUID()
        let event = CareEvent(id: UUID(), plantID: id, kind: .fertilizing, occurredAt: Date(), note: nil, createdAt: Date(), timeZoneIdentifier: "Europe/Madrid")
        for events in [[], [event]] {
            let result = try await LoadLastWatering(repository: WateringResult(events: events)).execute(for: id)
            XCTAssertNil(result)
        }
        do {
            _ = try await LoadLastWatering(repository: WateringResult(events: [], failure: true)).execute(for: id)
            XCTFail("Read errors must not become absence")
        } catch { XCTAssertEqual(error as? CareEventError, .storage) }
    }
}

private struct WateringResult: CareEventRepository {
    let events: [CareEvent]
    var failure = false
    func loadCareEvents(for plantID: UUID) async throws -> [CareEvent] {
        if failure { throw CareEventError.storage }
        return events
    }
    func saveCareEvent(_ event: CareEvent) async throws -> CareEvent { XCTFail("Reading must not write"); return event }
}
