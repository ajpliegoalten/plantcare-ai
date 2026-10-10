import AVFoundation
import UIKit

struct SystemCameraAccess: CameraAccess {
    func isAvailable() async -> Bool {
        #if targetEnvironment(simulator)
        // Simulator has no supported physical capture source. Avoid initializing
        // camera hardware services there (which can stall the first probe).
        return false
        #else
        return await MainActor.run { UIImagePickerController.isSourceTypeAvailable(.camera) }
        #endif
    }

    func authorization() async -> CameraAuthorization {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .restricted
        }
    }

    func requestAuthorization() async -> Bool { await AVCaptureDevice.requestAccess(for: .video) }
}
