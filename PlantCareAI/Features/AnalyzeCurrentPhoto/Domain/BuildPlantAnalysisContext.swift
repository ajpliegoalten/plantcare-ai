import Foundation

struct PlantAnalysisContext: Codable, Equatable, Sendable {
    struct Care: Codable, Equatable, Sendable { let kind: String; let date: String; let note: String?; let noteWasShortened: Bool }
    struct Previous: Codable, Equatable, Sendable { let photoDate: String; let interpretation: PlantPhotoAnalysisContent }
    struct Sheet: Codable, Equatable, Sendable {
        let light: String; let watering: String; let humidity: String
        let temperature: String; let substrate: String; let fertilizer: String
    }
    let species: String
    let currentCareSheet: Sheet
    let currentUserLocation: String?
    let photoDate: String
    let queryDate: String
    let referenceTimeZone: String
    var careEvents: [Care]
    var previousAcceptedInterpretations: [Previous]
    var omittedCareEvents: Int
    var omittedAcceptedInterpretations: Int

    func encoded() throws -> Data { let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; return try encoder.encode(self) }
}

struct BuildPlantAnalysisContext {
    func execute(plant: Plant, photo: PlantPhotoDescriptor, care: [CareEvent], accepted: [AcceptedPlantPhotoAnalysis],
                 queriedAt: Date, timeZone: TimeZone) throws -> PlantAnalysisContext {
        guard photo.date.timeIntervalSinceReferenceDate.isFinite, queriedAt.timeIntervalSinceReferenceDate.isFinite else {
            throw PlantPhotoAnalysisError.readFailure
        }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        let day = calendar.startOfDay(for: photo.date)
        guard care.filter({ $0.plantID == plant.id }).allSatisfy({ $0.occurredAt.timeIntervalSinceReferenceDate.isFinite && $0.createdAt.timeIntervalSinceReferenceDate.isFinite }),
              accepted.filter({ $0.plantID == plant.id }).allSatisfy({ $0.photoDate.timeIntervalSinceReferenceDate.isFinite }) else {
            throw PlantPhotoAnalysisError.readFailure
        }
        let cutoff = calendar.date(byAdding: .day, value: -90, to: day)!
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar; formatter.timeZone = timeZone; formatter.dateFormat = "yyyy-MM-dd"
        let priorCare = care.filter { $0.plantID == plant.id && calendar.startOfDay(for: $0.occurredAt) < day }
        let eligibleCare = priorCare.filter { calendar.startOfDay(for: $0.occurredAt) >= cutoff }.sorted {
            if $0.occurredAt != $1.occurredAt { return $0.occurredAt > $1.occurredAt }
            if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
        let prior = accepted.filter { $0.plantID == plant.id && $0.identity != photo.id && calendar.startOfDay(for: $0.photoDate) < day }.sorted {
            $0.photoDate == $1.photoDate ? $0.identity.stableKey < $1.identity.stableKey : $0.photoDate > $1.photoDate
        }
        let sheet = plant.careSheet
        var context = PlantAnalysisContext(species: plant.confirmedSpecies,
            currentCareSheet: .init(light: sheet.light, watering: sheet.watering, humidity: sheet.humidity,
                                    temperature: sheet.temperature, substrate: sheet.substrate, fertilizer: sheet.fertilizer),
            currentUserLocation: plant.location, photoDate: formatter.string(from: photo.date), queryDate: formatter.string(from: queriedAt),
            referenceTimeZone: timeZone.identifier, careEvents: [], previousAcceptedInterpretations: [],
            omittedCareEvents: priorCare.count, omittedAcceptedInterpretations: prior.count)
        guard try context.encoded().count <= 16 * 1024 else { throw PlantPhotoAnalysisError.contextTooLarge }
        context.careEvents = eligibleCare.prefix(20).map {
            .init(kind: $0.kind.rawValue, date: formatter.string(from: $0.occurredAt), note: $0.note.map { String($0.prefix(500)) },
                  noteWasShortened: ($0.note?.count ?? 0) > 500)
        }
        context.previousAcceptedInterpretations = try prior.prefix(5).map {
            .init(photoDate: formatter.string(from: $0.photoDate), interpretation: try $0.content.validated())
        }
        context.omittedCareEvents = priorCare.count - context.careEvents.count
        context.omittedAcceptedInterpretations = prior.count - context.previousAcceptedInterpretations.count
        while try context.encoded().count > 16 * 1024 {
            if !context.previousAcceptedInterpretations.isEmpty {
                context.previousAcceptedInterpretations.removeLast(); context.omittedAcceptedInterpretations += 1
            } else if !context.careEvents.isEmpty {
                context.careEvents.removeLast(); context.omittedCareEvents += 1
            } else { throw PlantPhotoAnalysisError.contextTooLarge }
        }
        return context
    }
}
