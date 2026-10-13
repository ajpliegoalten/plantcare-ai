import Foundation

protocol CareEventDeletingRepository: Sendable {
    func deleteCareEvent(_ expected: CareEvent) async throws -> CareEvent
}

enum CareEventError: Error, Equatable { case validation, plantNotFound, notFound, conflict, readFailure, storage }

protocol CareEventRepository: Sendable {
    func saveCareEvent(_ event: CareEvent) async throws -> CareEvent
    func loadCareEvents(for plantID: UUID) async throws -> [CareEvent]
}
