#if DEBUG && targetEnvironment(simulator)
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

final class PlantPhotoTestFixture: @unchecked Sendable {
    private let lock = NSLock()
    private var attempts = 0
    let mode: String
    init(mode: String) { self.mode = mode }
    func beforeCommit(_ photo: PlantPhoto) throws {
        lock.lock(); attempts += 1; let attempt = attempts; lock.unlock()
        if mode == "busy" { Thread.sleep(forTimeInterval: 8) }
        if mode == "errorOnce", attempt == 1 { throw PlantPhotoError.storage }
    }

    static func verify(repository: LocalPlantRepository, expectations: String) async throws {
        // Independent expectations supplied by the test, not snapshots emitted by the writer.
        // Format per plant: asset:day-offset,asset:day-offset;asset:day-offset.
        let groups = expectations.split(separator: ";", omittingEmptySubsequences: false)
        guard groups.count == 2 else { throw PlantPhotoError.storage }
        for index in 1...2 {
            let id = StorageTestFixture.plant(index).id
            let photos = try await repository.loadPhotos(for: id)
            let tokens = groups[index - 1].split(separator: ",")
            guard photos.count == tokens.count else { throw PlantPhotoError.storage }
            var remaining = photos
            for token in tokens {
                let parts = token.split(separator: ":")
                guard parts.count == 2, let offset = Int(parts[1]) else { throw PlantPhotoError.storage }
                // Native gallery expectations reproduce the public seed script's pixels.
                let asset = String(parts[0])
                let expectedPhoto: IdentificationPhoto?
                if let bytes = IdentificationPhotoTestFixture.selections()[asset] ?? galleryAsset(asset) {
                    expectedPhoto = try await LocalIdentificationPhotoPreparer().prepare(bytes)
                } else {
                    throw PlantPhotoError.storage
                }
                var match: Int?
                for (position, photo) in remaining.enumerated() {
                    let zone = try AddPlantPhoto.zone(photo.timeZoneIdentifier)
                    let calendar = AddPlantPhoto.calendar(in: zone)
                    guard let expectedDate = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: photo.createdAt)),
                          photo.occurredAt == expectedDate else { continue }
                    let bytes = try await repository.loadPhoto(id: photo.id, for: id)
                    if let expectedPhoto {
                        guard bytes == expectedPhoto.jpeg, photo.width == expectedPhoto.width, photo.height == expectedPhoto.height else { continue }
                    }
                    match = position; break
                }
                guard let match else { throw PlantPhotoError.storage }
                remaining.remove(at: match)
            }
            let events = try await repository.loadCareEvents(for: id)
            guard events.isEmpty else { throw PlantPhotoError.storage }
        }
    }
    private static func galleryAsset(_ name: String) -> Data? {
        guard ["gallery-A", "gallery-B"].contains(name) else { return nil }
        let isA = name == "gallery-A", width = isA ? 160 : 80, height = isA ? 80 : 160
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        context.setFillColor(CGColor(red: isA ? 0.1 : 0.9, green: isA ? 0.7 : 0.2, blue: 0.1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(CGRect(x: 0, y: height - 20, width: 20, height: 20))
        let data = NSMutableData()
        guard let image = context.makeImage(), let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }; return data as Data
    }
}

actor PlantPhotoReadTestFixture: PlantPhotoRepository {
    private let repository: LocalPlantRepository
    private let mode: String
    private var metadataReads = 0
    private var imageReads: [UUID: Int] = [:]
    init(repository: LocalPlantRepository, mode: String) { self.repository = repository; self.mode = mode }
    func savePhoto(_ photo: PlantPhoto, jpeg: Data) async throws -> PlantPhoto {
        try await repository.savePhoto(photo, jpeg: jpeg)
    }
    func loadPhotos(for plantID: UUID) async throws -> [PlantPhoto] {
        metadataReads += 1
        if mode == "metadataErrorOnce", metadataReads == 1 { throw PlantPhotoError.storage }
        return try await repository.loadPhotos(for: plantID)
    }
    func loadPhoto(id: UUID, for plantID: UUID) async throws -> Data {
        imageReads[id, default: 0] += 1
        if mode == "imageErrorOnce", imageReads[id] == 1 { throw PlantPhotoError.photoMissing }
        return try await repository.loadPhoto(id: id, for: plantID)
    }
}
#endif
