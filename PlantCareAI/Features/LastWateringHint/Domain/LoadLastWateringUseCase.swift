import Foundation

protocol LoadLastWateringUseCase: Sendable {
    func execute(for plantID: UUID) async throws -> Date?
}

struct LoadLastWatering: LoadLastWateringUseCase {
    let repository: any CareEventRepository

    func execute(for plantID: UUID) async throws -> Date? {
        try await repository.loadCareEvents(for: plantID)
            .filter { $0.plantID == plantID && $0.kind == .watering }
            .map(\.occurredAt).max()
    }
}
