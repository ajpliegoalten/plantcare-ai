import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

struct LocalIdentificationPhotoPreparer: IdentificationPhotoPreparing {
    static let maximumInputBytes = 30 * 1024 * 1024
    static let maximumPixels = 80_000_000
    static let maximumSide = 2048
    static let maximumOutputBytes = 5 * 1024 * 1024

    func prepare(_ data: Data) async throws -> IdentificationPhoto {
        // Detached work keeps ImageIO decode/encode off the UI executor. Cancellation
        // is forwarded and checked between synchronous framework operations.
        let worker = Task.detached(priority: .userInitiated) { try Self.process(data) }
        return try await withTaskCancellationHandler(operation: { try await worker.value }, onCancel: { worker.cancel() })
    }

    private static func process(_ data: Data) throws -> IdentificationPhoto {
        try Task.checkCancellation()
        guard !data.isEmpty else { throw IdentificationPhotoError.empty }
        guard data.count <= maximumInputBytes else { throw IdentificationPhotoError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let type = CGImageSourceGetType(source), UTType(type as String)?.conforms(to: .image) == true else {
            throw IdentificationPhotoError.unsupported
        }
        guard CGImageSourceGetCount(source) > 0, CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else { throw IdentificationPhotoError.decodeFailed }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { throw IdentificationPhotoError.decodeFailed }
        guard width <= maximumPixels / height else { throw IdentificationPhotoError.tooLarge }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: min(maximumSide, max(width, height)),
            kCGImageSourceShouldCacheImmediately: true]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let context = CGContext(data: nil, width: thumbnail.width, height: thumbnail.height,
                bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw IdentificationPhotoError.decodeFailed }
        try Task.checkCancellation()
        let rect = CGRect(x: 0, y: 0, width: thumbnail.width, height: thumbnail.height)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(rect)
        context.draw(thumbnail, in: rect)
        guard let flattened = context.makeImage() else { throw IdentificationPhotoError.decodeFailed }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw IdentificationPhotoError.decodeFailed
        }
        // Only compression is supplied: no source EXIF, GPS or orientation survives.
        CGImageDestinationAddImage(destination, flattened, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw IdentificationPhotoError.decodeFailed }
        try Task.checkCancellation()
        let jpeg = try removingEncoderExif(output as Data)
        guard jpeg.count <= maximumOutputBytes else { throw IdentificationPhotoError.tooLarge }
        return IdentificationPhoto(id: UUID(), jpeg: jpeg, width: flattened.width, height: flattened.height)
    }

    /// ImageIO may generate a minimal EXIF block containing dimensions even when
    /// no source properties are supplied. Remove APP1 from our own encoded JPEG
    /// so the ephemeral transport has no EXIF/GPS at all. Scan data is untouched.
    private static func removingEncoderExif(_ jpeg: Data) throws -> Data {
        guard jpeg.count >= 2, jpeg[0] == 0xff, jpeg[1] == 0xd8 else { throw IdentificationPhotoError.decodeFailed }
        var result = Data(jpeg.prefix(2))
        var offset = 2
        while offset + 3 < jpeg.count {
            guard jpeg[offset] == 0xff else { throw IdentificationPhotoError.decodeFailed }
            let marker = jpeg[offset + 1]
            if marker == 0xda { result.append(jpeg[offset...]); return result }
            let length = Int(jpeg[offset + 2]) * 256 + Int(jpeg[offset + 3])
            guard length >= 2, offset + 2 + length <= jpeg.count else { throw IdentificationPhotoError.decodeFailed }
            if marker != 0xe1 { result.append(jpeg[offset..<(offset + 2 + length)]) }
            offset += 2 + length
        }
        throw IdentificationPhotoError.decodeFailed
    }
}
