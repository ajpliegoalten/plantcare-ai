import Foundation

enum PlantDeletionError: Error, Equatable {
    case notFound, conflict, readFailure, storage
}

protocol PlantDeletingRepository: Sendable {
    func deletePlant(_ expected: Plant) async throws -> Plant
}
