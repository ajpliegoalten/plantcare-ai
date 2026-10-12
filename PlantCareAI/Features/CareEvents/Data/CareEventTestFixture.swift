#if DEBUG && targetEnvironment(simulator)
import Foundation

// Opt-in UUID-scoped simulator store only. Expected dispatch payloads are not product history.
final class CareEventTestFixture: @unchecked Sendable {
    private struct Payload: Codable, Equatable {
        let id: UUID
        let plantID: UUID
        let kind: String
        let occurredAt: Double
        let note: String?
        let createdAt: Double
        let timeZoneIdentifier: String
        init(_ event: CareEvent) {
            id = event.id; plantID = event.plantID; kind = event.kind.rawValue
            occurredAt = event.occurredAt.timeIntervalSinceReferenceDate
            note = event.note; createdAt = event.createdAt.timeIntervalSinceReferenceDate
            timeZoneIdentifier = event.timeZoneIdentifier
        }
        static func == (lhs: Payload, rhs: Payload) -> Bool {
            lhs.id == rhs.id && lhs.plantID == rhs.plantID && lhs.kind == rhs.kind &&
            lhs.occurredAt == rhs.occurredAt && lhs.createdAt == rhs.createdAt &&
            lhs.timeZoneIdentifier == rhs.timeZoneIdentifier && CareEvent.identicalNotes(lhs.note, rhs.note)
        }
    }
    private let root: URL
    private let mode: String
    private let lock = NSLock()
    private var attempts = 0
    init(root: URL, mode: String) { self.root = root; self.mode = mode }

    func beforeCareCommit(_ event: CareEvent) throws {
        lock.lock(); defer { lock.unlock() }
        attempts += 1
        let url = root.appendingPathComponent("CareExpected.json")
        var expected = FileManager.default.fileExists(atPath: url.path) ? try JSONDecoder().decode([Payload].self, from: Data(contentsOf: url)) : []
        let payload = Payload(event)
        if let existing = expected.first(where: { $0.id == payload.id }) {
            guard existing == payload else { throw CareEventError.conflict }
        } else { expected.append(payload) }
        try JSONEncoder().encode(expected).write(to: url, options: .atomic)
        if mode == "busy" { Thread.sleep(forTimeInterval: 12) }
        if mode == "fail-first", attempts == 1 { throw CareEventError.storage }
    }

    static func verify(root: URL, repository: LocalPlantRepository, count: Int, arguments: [String] = ProcessInfo.processInfo.arguments) async throws {
        let url = root.appendingPathComponent("CareExpected.json")
        let expected = FileManager.default.fileExists(atPath: url.path) ? try JSONDecoder().decode([Payload].self, from: Data(contentsOf: url)) : []
        let actual = try await repository.loadCareEvents(for: StorageTestFixture.plant(1).id)
        let other = try await repository.loadCareEvents(for: StorageTestFixture.plant(2).id)
        guard actual.count == count, other.isEmpty,
              actual.map(Payload.init).sorted(by: { $0.id.uuidString < $1.id.uuidString }) == expected.filter({ payload in actual.contains(where: { $0.id == payload.id }) }).sorted(by: { $0.id.uuidString < $1.id.uuidString }) else { throw CareEventError.storage }
        if let position = arguments.firstIndex(of: "--care-expected-offset"), arguments.indices.contains(position + 1), let offset = Int(arguments[position + 1]) {
            for event in actual {
                let calendar = RegisterCareEvent.calendar(in: try RegisterCareEvent.zone(event.timeZoneIdentifier))
                guard event.occurredAt == calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: event.createdAt)) else { throw CareEventError.storage }
            }
        }
        if let position = arguments.firstIndex(of: "--care-expected-note-base64") {
            guard arguments.indices.contains(position + 1), let data = Data(base64Encoded: arguments[position + 1]),
                  let note = String(data: data, encoding: .utf8) else { throw CareEventError.storage }
            guard actual.allSatisfy({ CareEvent.identicalNotes($0.note, note) }) else { throw CareEventError.storage }
        } else if !arguments.contains("--care-expectations-base64") { guard actual.allSatisfy({ $0.note == nil }) else { throw CareEventError.storage } }
        if let position = arguments.firstIndex(of: "--care-expectations-base64") {
            struct Expectation: Decodable { let kind: String; let note: String?; let offset: Int }
            guard arguments.indices.contains(position + 1), let data = Data(base64Encoded: arguments[position + 1]) else { throw CareEventError.storage }
            let independent = try JSONDecoder().decode([Expectation].self, from: data)
            var unmatched = actual
            for wanted in independent {
                guard let index = unmatched.firstIndex(where: { event in
                    guard let zone = try? RegisterCareEvent.zone(event.timeZoneIdentifier) else { return false }
                    let calendar = RegisterCareEvent.calendar(in: zone)
                    return event.kind.rawValue == wanted.kind && CareEvent.identicalNotes(event.note, wanted.note) &&
                        event.occurredAt == calendar.date(byAdding: .day, value: wanted.offset, to: calendar.startOfDay(for: event.createdAt))
                }) else { throw CareEventError.storage }
                unmatched.remove(at: index)
            }
            guard unmatched.isEmpty else { throw CareEventError.storage }
        } else {
            guard actual.allSatisfy({ $0.kind == .watering }) else { throw CareEventError.storage }
        }
    }
}
#endif
