import XCTest
import ImageIO
import UniformTypeIdentifiers
@testable import PlantCareAI

final class PreparedPlantPhotoValidationTests: XCTestCase {
    func testRejectExcludedSourceMetadataAndPNGEvenWithMatchingDimensions() async throws {
        let photo = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(1))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(photo.jpeg as CFData, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        for (type, properties) in [(UTType.jpeg, [kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "private"]] as CFDictionary), (.jpeg, [kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 12.0]] as CFDictionary), (.jpeg, [kCGImagePropertyOrientation: 6] as CFDictionary), (.png, [:] as CFDictionary)] {
            let output = NSMutableData()
            let destination = try XCTUnwrap(CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, properties); XCTAssertTrue(CGImageDestinationFinalize(destination))
            do {
                try await LocalPreparedPlantPhotoValidator().validate(IdentificationPhoto(id: UUID(), jpeg: output as Data, width: photo.width, height: photo.height))
                XCTFail("Source metadata or non-JPEG accepted")
            } catch { XCTAssertEqual(error as? PlantStorageError, .photoCorrupt) }
        }
    }
    func testAcceptPreparedOutputAndRejectBytesDimensionsBoundsAndCancellation() async throws {
        let photo = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(1))
        let validator = LocalPreparedPlantPhotoValidator()
        try await validator.validate(photo)
        for invalid in [IdentificationPhoto(id: photo.id, jpeg: photo.jpeg, width: photo.width + 1, height: photo.height), IdentificationPhoto(id: photo.id, jpeg: photo.jpeg, width: 0, height: photo.height), IdentificationPhoto(id: photo.id, jpeg: photo.jpeg, width: 2049, height: 1), IdentificationPhoto(id: photo.id, jpeg: Data(photo.jpeg.prefix(photo.jpeg.count / 2)), width: photo.width, height: photo.height), IdentificationPhoto(id: photo.id, jpeg: Data(repeating: 0, count: 5 * 1024 * 1024 + 1), width: 1, height: 1)] {
            do { try await validator.validate(invalid); XCTFail("Invalid prepared photo accepted") }
            catch { XCTAssertEqual(error as? PlantStorageError, .photoCorrupt) }
        }
        let task = Task { try await validator.validate(photo) }; task.cancel()
        do { try await task.value; XCTFail("Cancellation ignored") } catch { XCTAssertTrue(error is CancellationError) }
    }
}
