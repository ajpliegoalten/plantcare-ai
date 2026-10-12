import Foundation

enum CareEventError: Error, Equatable { case validation, plantNotFound, conflict, storage }

protocol CareEventRepository: Sendable {
    func saveCareEvent(_ event: CareEvent) async throws -> CareEvent
    func loadCareEvents(for plantID: UUID) async throws -> [CareEvent]
}
