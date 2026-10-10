import XCTest
import ImageIO
import UniformTypeIdentifiers
import UIKit
@testable import PlantCareAI

final class IdentificationPhotoPreparationTests: XCTestCase {
    private func image(type: UTType = .png, width: Int = 40, height: Int = 20, orientation: Int = 1) throws -> Data {
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let output = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try XCTUnwrap(context.makeImage()), [
            kCGImagePropertyOrientation: orientation,
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "private"],
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 12.0]
        ] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return output as Data
    }

    func testFormatsOrientationAndMetadataRemoval() async throws {
        for type in [UTType.jpeg, .png, .heic] {
            let photo = try await LocalIdentificationPhotoPreparer().prepare(image(type: type, orientation: 6))
            XCTAssertEqual(photo.width, 20)
            XCTAssertEqual(photo.height, 40)
            let source = try XCTUnwrap(CGImageSourceCreateWithData(photo.jpeg as CFData, nil))
            XCTAssertEqual(CGImageSourceGetType(source) as String?, UTType.jpeg.identifier)
            let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
            XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
            XCTAssertNil(properties[kCGImagePropertyExifDictionary])
            XCTAssertNil(properties[kCGImagePropertyOrientation])
        }
    }

    func testThumbnailBoundsNoUpscalingAndWhiteAlpha() async throws {
        let small = try await LocalIdentificationPhotoPreparer().prepare(image())
        XCTAssertEqual(small.width, 40)
        XCTAssertEqual(small.height, 20)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(small.jpeg as CFData, nil))
        let decoded = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try XCTUnwrap(CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(decoded, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let pixel = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        XCTAssertGreaterThan(pixel[0], 245)
        XCTAssertGreaterThan(pixel[1], 245)
        XCTAssertGreaterThan(pixel[2], 245)
        let large = try await LocalIdentificationPhotoPreparer().prepare(image(width: 4096, height: 2048))
        XCTAssertEqual(large.width, 2048)
        XCTAssertEqual(large.height, 1024)
        XCTAssertLessThanOrEqual(large.jpeg.count, LocalIdentificationPhotoPreparer.maximumOutputBytes)
    }

    func testInvalidAndEncodedSizeLimits() async {
        for (bytes, expected) in [(Data(), IdentificationPhotoError.empty), (Data("not an image".utf8), .unsupported),
                                 (Data(repeating: 0, count: LocalIdentificationPhotoPreparer.maximumInputBytes + 1), .tooLarge)] {
            do { _ = try await LocalIdentificationPhotoPreparer().prepare(bytes); XCTFail("Unexpected success") }
            catch { XCTAssertEqual(error as? IdentificationPhotoError, expected) }
        }
    }

    func testCancelledPreparationDoesNotReturnPhoto() async throws {
        let bytes = try image()
        let task = Task { try await PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()).execute(bytes) }
        task.cancel()
        do { _ = try await task.value; XCTFail("Cancelled task returned photo") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    func testTruncatedImageAndCameraTransportOrientation() async throws {
        let bytes = try image(type: .jpeg)
        do { _ = try await LocalIdentificationPhotoPreparer().prepare(Data(bytes.prefix(bytes.count / 2))); XCTFail("Truncated image accepted") }
        catch { XCTAssertTrue(error is IdentificationPhotoError) }
        let source = try XCTUnwrap(CGImageSourceCreateWithData(try image() as CFData, nil))
        let bitmap = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let transport = try XCTUnwrap(UIImage(cgImage: bitmap, scale: 1, orientation: .right).jpegData(compressionQuality: 0.95))
        let photo = try await LocalIdentificationPhotoPreparer().prepare(transport)
        XCTAssertEqual(photo.width, 20)
        XCTAssertEqual(photo.height, 40)
    }

    func testPixelLimitIsCheckedBeforeThumbnailDecode() async throws {
        var bytes = try image(type: .jpeg)
        var offset = 2
        while offset + 8 < bytes.count {
            let marker = bytes[offset + 1]
            if [0xc0, 0xc1, 0xc2].contains(marker) {
                // JPEG SOF dimensions 9000 x 9000, without allocating that bitmap.
                bytes.replaceSubrange((offset + 5)..<(offset + 9), with: [0x23, 0x28, 0x23, 0x28])
                break
            }
            offset += 2 + Int(bytes[offset + 2]) * 256 + Int(bytes[offset + 3])
        }
        do { _ = try await LocalIdentificationPhotoPreparer().prepare(bytes); XCTFail("Oversized pixels decoded") }
        catch { XCTAssertEqual(error as? IdentificationPhotoError, .tooLarge) }
    }
}
