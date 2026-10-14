import Foundation

struct PlantQuestionContext: Codable, Equatable, Sendable {
    let question: String
    let species: String
    let currentCareSheet: PlantAnalysisContext.Sheet
    let currentUserLocation: String?
    let queryDate: String
    let referenceTimeZone: String
    var careEvents: [PlantAnalysisContext.Care]
    var previousAcceptedInterpretations: [PlantAnalysisContext.Previous]
    var omittedCareEvents: Int
    var omittedAcceptedInterpretations: Int
    func encoded() throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }
}
struct BuildPlantQuestionContext {
    func execute(plant: Plant, question: String, care: [CareEvent], analyses: [SavedPlantPhotoAnalysis], queriedAt: Date, timeZone: TimeZone) throws -> PlantQuestionContext {
        let question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, question.count <= 2000 else { throw PlantQuestionError.invalidQuestion }
        let ownCare = care.filter { $0.plantID == plant.id }, ownAnalyses = analyses.filter { $0.plantID == plant.id }
        guard queriedAt.timeIntervalSinceReferenceDate.isFinite,
              ownCare.allSatisfy({ $0.occurredAt.timeIntervalSinceReferenceDate.isFinite && $0.createdAt.timeIntervalSinceReferenceDate.isFinite }),
              ownAnalyses.allSatisfy({ $0.photoDate.timeIntervalSinceReferenceDate.isFinite && $0.acceptedAt.timeIntervalSinceReferenceDate.isFinite }) else { throw PlantQuestionError.readFailure }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: queriedAt)
        guard let cutoff = calendar.date(byAdding: .day, value: -89, to: today) else { throw PlantQuestionError.readFailure }
        let events = ownCare.filter {
            let day = calendar.startOfDay(for: $0.occurredAt)
            return day >= cutoff && day <= today && $0.createdAt <= queriedAt
        }.sorted {
            if $0.occurredAt != $1.occurredAt { return $0.occurredAt > $1.occurredAt }
            if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
        let previous = ownAnalyses.filter { calendar.startOfDay(for: $0.photoDate) <= today && $0.acceptedAt <= queriedAt }.sorted {
            $0.photoDate == $1.photoDate ? $0.identity.stableKey < $1.identity.stableKey : $0.photoDate > $1.photoDate
        }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar; formatter.timeZone = timeZone; formatter.dateFormat = "yyyy-MM-dd"
        let sheet = plant.careSheet
        var context = PlantQuestionContext(question: question, species: plant.confirmedSpecies,
            currentCareSheet: .init(light: sheet.light, watering: sheet.watering, humidity: sheet.humidity, temperature: sheet.temperature, substrate: sheet.substrate, fertilizer: sheet.fertilizer),
            currentUserLocation: plant.location, queryDate: formatter.string(from: queriedAt), referenceTimeZone: timeZone.identifier,
            careEvents: [], previousAcceptedInterpretations: [], omittedCareEvents: events.count, omittedAcceptedInterpretations: previous.count)
        guard try context.encoded().count <= 16384 else { throw PlantQuestionError.contextTooLarge }
        context.careEvents = events.prefix(20).map {
            .init(kind: $0.kind.rawValue, date: formatter.string(from: $0.occurredAt), note: $0.note.map { String($0.prefix(500)) }, noteWasShortened: ($0.note?.count ?? 0) > 500)
        }
        context.previousAcceptedInterpretations = try previous.prefix(5).map {
            .init(photoDate: formatter.string(from: $0.photoDate), interpretation: try $0.content.validated())
        }
        context.omittedCareEvents = events.count - context.careEvents.count; context.omittedAcceptedInterpretations = previous.count - context.previousAcceptedInterpretations.count
        while try context.encoded().count > 16384 {
            if !context.previousAcceptedInterpretations.isEmpty { context.previousAcceptedInterpretations.removeLast(); context.omittedAcceptedInterpretations += 1 }
            else if !context.careEvents.isEmpty { context.careEvents.removeLast(); context.omittedCareEvents += 1 }
            else { throw PlantQuestionError.contextTooLarge }
        }
        return context
    }
}
