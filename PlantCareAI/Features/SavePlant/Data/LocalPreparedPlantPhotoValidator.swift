import Foundation
import ImageIO
import UniformTypeIdentifiers

struct LocalPreparedPlantPhotoValidator: PreparedPlantPhotoValidating {
    func validate(_ photo: IdentificationPhoto) async throws {
        let task = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            guard !photo.jpeg.isEmpty, photo.jpeg.count <= 5 * 1024 * 1024,
                  photo.jpeg.prefix(2) == Data([0xff, 0xd8]),
                  photo.jpeg.suffix(2) == Data([0xff, 0xd9]),
                  photo.width > 0, photo.height > 0, max(photo.width, photo.height) <= 2048,
                  let source = CGImageSourceCreateWithData(photo.jpeg as CFData, nil),
                  CGImageSourceGetType(source) as String? == UTType.jpeg.identifier,
                  CGImageSourceGetCount(source) == 1,
                  CGImageSourceGetStatus(source) == .statusComplete,
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  properties[kCGImagePropertyPixelWidth] as? Int == photo.width,
                  properties[kCGImagePropertyPixelHeight] as? Int == photo.height,
                  properties[kCGImagePropertyExifDictionary] == nil,
                  properties[kCGImagePropertyGPSDictionary] == nil,
                  properties[kCGImagePropertyOrientation] == nil,
                  let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary),
                  image.width == photo.width, image.height == photo.height,
                  CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
                throw PlantStorageError.photoCorrupt
            }
            try Task.checkCancellation()
        }
        try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }
}
