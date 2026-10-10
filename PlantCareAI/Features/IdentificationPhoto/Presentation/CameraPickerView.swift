import SwiftUI
import UniformTypeIdentifiers

struct CameraPickerView: UIViewControllerRepresentable {
    let completion: (Data?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier]
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let completion: (Data?) -> Void
        init(completion: @escaping (Data?) -> Void) { self.completion = completion }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil) }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else { completion(Data()); return }
            // UIImage JPEG export includes orientation. Preparation normalizes it off MainActor.
            Task.detached(priority: .userInitiated) { [completion] in
                let bytes = image.jpegData(compressionQuality: 0.95) ?? Data()
                await MainActor.run { completion(bytes) }
            }
        }
    }
}
