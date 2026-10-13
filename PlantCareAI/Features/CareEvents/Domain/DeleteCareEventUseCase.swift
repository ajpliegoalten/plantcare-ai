import Foundation

protocol DeleteCareEventUseCase: Sendable {
    func execute(_ expected: CareEvent) async throws -> CareEvent
}

struct DeleteCareEvent: DeleteCareEventUseCase {
    let repository: any CareEventDeletingRepository
    func execute(_ expected: CareEvent) async throws -> CareEvent {
        // Historical snapshots must not be revalidated against today's clock.
        try await repository.deleteCareEvent(expected)
    }
}
