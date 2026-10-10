import Foundation

enum CameraAuthorization: Sendable { case notDetermined, authorized, denied, restricted }
enum CameraAccessResult: Sendable, Equatable { case authorized, unavailable, denied, restricted }

protocol CameraAccess: Sendable {
    func isAvailable() async -> Bool
    func authorization() async -> CameraAuthorization
    func requestAuthorization() async -> Bool
}

struct CheckCameraAccess: Sendable {
    let access: any CameraAccess

    /// Called only by the user's capture intention. Rechecks on every attempt.
    func execute() async throws -> CameraAccessResult {
        try Task.checkCancellation()
        let available = await access.isAvailable()
        try Task.checkCancellation()
        guard available else { return .unavailable }
        let authorization = await access.authorization()
        try Task.checkCancellation()
        switch authorization {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined:
            let granted = await access.requestAuthorization()
            try Task.checkCancellation()
            return granted ? .authorized : .denied
        }
    }
}
