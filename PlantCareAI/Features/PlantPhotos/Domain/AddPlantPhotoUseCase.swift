import Foundation

struct AddPlantPhoto {
    let repository: any PlantPhotoRepository

    func execute(photo: PlantPhoto, jpeg: Data) async throws -> PlantPhoto {
        try Self.validateStructure(photo)
        guard !jpeg.isEmpty, jpeg.count <= 5 * 1024 * 1024 else { throw PlantPhotoError.validation }
        return try await repository.savePhoto(photo, jpeg: jpeg)
    }

    static func calendar(in zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    static func zone(_ identifier: String) throws -> TimeZone {
        guard identifier.contains("/"), !identifier.hasPrefix("Etc/GMT"),
              TimeZone.knownTimeZoneIdentifiers.contains(identifier), let zone = TimeZone(identifier: identifier) else {
            throw PlantPhotoError.validation
        }
        return zone
    }

    static func startOfDay(year: Int, month: Int, day: Int, zone: TimeZone) throws -> Date {
        let calendar = calendar(in: zone)
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            throw PlantPhotoError.validation
        }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        guard resolved.year == year, resolved.month == month, resolved.day == day else { throw PlantPhotoError.validation }
        return calendar.startOfDay(for: date)
    }

    static func validateStructure(_ photo: PlantPhoto) throws {
        guard photo.occurredAt.timeIntervalSinceReferenceDate.isFinite,
              photo.createdAt.timeIntervalSinceReferenceDate.isFinite,
              photo.width > 0, photo.height > 0, max(photo.width, photo.height) <= 2048 else {
            throw PlantPhotoError.validation
        }
        let calendar = calendar(in: try zone(photo.timeZoneIdentifier))
        guard calendar.startOfDay(for: photo.occurredAt) == photo.occurredAt else { throw PlantPhotoError.validation }
    }

    static func validateInsertion(_ photo: PlantPhoto, now: Date) throws {
        try validateStructure(photo)
        guard now.timeIntervalSinceReferenceDate.isFinite, photo.occurredAt <= now,
              photo.occurredAt <= calendar(in: try zone(photo.timeZoneIdentifier)).startOfDay(for: now) else {
            throw PlantPhotoError.validation
        }
    }
}
