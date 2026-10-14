import XCTest
@testable import PlantCareAI

actor QuestionLocalSpy: PlantRepository, CareEventRepository, SavedPlantPhotoAnalysisReading {
    var plants = [BuildPlantAnalysisContextTests.plant(), BuildPlantAnalysisContextTests.plant(id: UUID(), location: "B")]
    var events: [CareEvent] = []
    var records: [SavedPlantPhotoAnalysis] = []
    var failure = false
    var analysisFailure = false
    var writes = 0; var photoReads = 0
    func loadPlants() async throws -> [Plant] { plants }
    func updatePlant(id: UUID, name: String, location: String?) async throws -> Plant { writes += 1; return plants[0] }
    func savePlant(_ plant: Plant, initialPhoto: Data) async throws { writes += 1 }
    func loadInitialPhoto(for id: UUID) async throws -> Data { photoReads += 1; return Data() }
    func loadCareEvents(for id: UUID) async throws -> [CareEvent] { if failure { throw PlantQuestionError.readFailure }; return events }
    func saveCareEvent(_ event: CareEvent) async throws -> CareEvent { writes += 1; return event }
    func loadSavedAnalyses(for id: UUID) async throws -> [SavedPlantPhotoAnalysis] { if failure || analysisFailure { throw PlantQuestionError.readFailure }; return records }
    func failAnalyses() { analysisFailure = true }
    func configure(failure: Bool = false, plants: [Plant]? = nil) { self.failure = failure; if let plants { self.plants = plants } }
}
actor QuestionProviderSpy: PlantQuestionRepository {
    var contexts: [PlantQuestionContext] = []
    var hold = false; var failure: PlantQuestionError?
    var continuation: CheckedContinuation<Void, Never>?
    func ask(context: PlantQuestionContext) async throws -> PlantQuestionAnswer {
        contexts.append(context)
        if hold { await withCheckedContinuation { continuation = $0 } }
        if let failure { throw failure }
        return .init(answer: "Orientación: " + context.question)
    }
    func configure(hold: Bool = false, failure: PlantQuestionError? = nil) { self.hold = hold; self.failure = failure }
    func release() { hold = false; continuation?.resume(); continuation = nil }
}
final class AskPlantQuestionTests: XCTestCase {
    func testDefinitiveReaderFailureAndWrongLeaseCompletionFailClosed() async throws {
        let local = QuestionLocalSpy(), provider = QuestionProviderSpy(), use = use(local, provider)
        await local.failAnalyses()
        do { _ = try await prepare(use); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, .readFailure) }
        let calls = await provider.contexts; XCTAssertTrue(calls.isEmpty)
        let gate = PlantQuestionOperationGate(), plantID = UUID(), owner = UUID()
        try await gate.begin(plantID: plantID, requestID: owner)
        await gate.end(plantID: plantID, requestID: UUID())
        do { try await gate.begin(plantID: plantID, requestID: UUID()); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, .busy) }
        try await gate.begin(plantID: UUID(), requestID: UUID())
        await gate.end(plantID: plantID, requestID: owner)
        try await gate.begin(plantID: plantID, requestID: UUID())
    }
    private struct DiskSnapshot: Equatable {
        let plants: [Plant]
        let care: [[CareEvent]]
        let photos: [[PlantPhoto]]
        let analyses: [[SavedPlantPhotoAnalysis]]
        let jpeg: [Data]
    }
    private func snapshot(_ repository: LocalPlantRepository) async throws -> DiskSnapshot {
        let plants = try await repository.loadPlants()
        var care: [[CareEvent]] = [], photos: [[PlantPhoto]] = [], analyses: [[SavedPlantPhotoAnalysis]] = [], jpeg: [Data] = []
        for plant in plants {
            care.append(try await repository.loadCareEvents(for: plant.id))
            let records = try await repository.loadPhotos(for: plant.id); photos.append(records)
            analyses.append(try await repository.loadSavedAnalyses(for: plant.id))
            jpeg.append(try await repository.loadInitialPhoto(for: plant.id))
            for photo in records { jpeg.append(try await repository.loadPhoto(id: photo.id, for: plant.id)) }
        }
        return .init(plants: plants, care: care, photos: photos, analyses: analyses, jpeg: jpeg)
    }
    func testRealDiskFourEntitiesJPEGDefinitivesAndReopenRemainExactForBothPlants() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        var store: LocalPlantRepository? = LocalPlantRepository(root: root)
        let date = BuildPlantAnalysisContextTests.date
        for index in 1...2 {
            let plant = StorageTestFixture.plant(index)
            try await store!.savePlant(plant, initialPhoto: StorageTestFixture.photo(index))
            _ = try await store!.saveCareEvent(.init(id: UUID(), plantID: plant.id, kind: .other, occurredAt: date(99), note: "Solo planta \(index)", createdAt: date(99), timeZoneIdentifier: "Africa/Abidjan"))
            _ = try await store!.saveAccepted(KeepPlantPhotoAnalysisTests.snapshot(plant: plant))
        }
        let jpeg = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2))
        _ = try await store!.savePhoto(.init(id: UUID(), plantID: StorageTestFixture.plant(1).id, occurredAt: date(99), createdAt: date(99), timeZoneIdentifier: "Africa/Abidjan", width: jpeg.width, height: jpeg.height), jpeg: jpeg.jpeg)
        let before = try await snapshot(store!), provider = QuestionProviderSpy()
        for plant in before.plants {
            let use = AskPlantQuestion(detail: .init(repository: store!), care: store!, analyses: store!, repository: provider, gate: .init())
            let value = try await use.prepare(plantID: plant.id, question: "Consulta \(plant.id)", queriedAt: date(1000), timeZone: TimeZone(secondsFromGMT: 0)!)
            XCTAssertEqual(value.context.previousAcceptedInterpretations.count, 1)
            _ = try await use.execute(value)
            let after = try await snapshot(store!); XCTAssertEqual(after, before)
        }
        store = nil
        let reopened = LocalPlantRepository(root: root), after = try await snapshot(reopened)
        XCTAssertEqual(after, before)
    }
    func use(_ local: QuestionLocalSpy, _ provider: QuestionProviderSpy, gate: PlantQuestionOperationGate = .init()) -> AskPlantQuestion {
        .init(detail: LoadPlantDetail(repository: local), care: local, analyses: local, repository: provider, gate: gate)
    }
    func prepare(_ use: AskPlantQuestion, id: UUID = BuildPlantAnalysisContextTests.plantID, question: String = "¿Qué revisar?") async throws -> PreparedPlantQuestion {
        try await use.prepare(plantID: id, question: question, queriedAt: BuildPlantAnalysisContextTests.date(100), timeZone: TimeZone(secondsFromGMT: 0)!)
    }
    func testIndependentQuestionsTwoPlantsReadOnlyNoJPEGNoPreviousQueries() async throws {
        let local = QuestionLocalSpy(), provider = QuestionProviderSpy(), use = use(local, provider)
        let plants = try await local.loadPlants()
        for (id, question) in [(plants[0].id, "primera"), (plants[0].id, "segunda"), (plants[1].id, "tercera")] {
            let value = try await prepare(use, id: id, question: question), result = try await use.execute(value)
            XCTAssertEqual(result.plantID, id); XCTAssertEqual(result.requestID, value.requestID); XCTAssertEqual(result.question, question)
        }
        let contexts = await provider.contexts
        XCTAssertEqual(contexts.map(\.question), ["primera", "segunda", "tercera"])
        XCTAssertEqual(contexts.map(\.currentUserLocation), ["Interior", "Interior", "B"])
        XCTAssertFalse(String(decoding: try contexts[1].encoded(), as: UTF8.self).contains("primera"))
        let writes = await local.writes, photos = await local.photoReads
        XCTAssertEqual(writes, 0); XCTAssertEqual(photos, 0)
    }
    func testReadersFailureMissingAndChangedPlantBeforeDispatchPreventHTTP() async throws {
        let local = QuestionLocalSpy(), provider = QuestionProviderSpy(), use = use(local, provider)
        await local.configure(failure: true)
        do { _ = try await prepare(use); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, .readFailure) }
        await local.configure(); let value = try await prepare(use)
        await local.configure(plants: [])
        do { _ = try await use.execute(value); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, .notFound) }
        await local.configure(plants: [BuildPlantAnalysisContextTests.plant(location: "cambio")])
        do { _ = try await use.execute(value); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, .stale) }
        let calls = await provider.contexts; XCTAssertTrue(calls.isEmpty)
    }
    func testCancellationDrainsLeaseAndLateDeletedPlantCannotPublish() async throws {
        let local = QuestionLocalSpy(), provider = QuestionProviderSpy(), gate = PlantQuestionOperationGate(), use = use(local, provider, gate: gate)
        await provider.configure(hold: true)
        let value = try await prepare(use), task = Task { try await use.execute(value) }
        for _ in 0..<1000 { if await provider.continuation != nil { break }; try await Task.sleep(for: .milliseconds(2)) }
        task.cancel()
        do { _ = try await use.execute(value); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, .busy) }
        await provider.release()
        do { _ = try await task.value; XCTFail() } catch { XCTAssertTrue(error is CancellationError) }
        await provider.configure(hold: true)
        let next = Task { try await use.execute(value) }
        for _ in 0..<1000 { if await provider.continuation != nil { break }; try await Task.sleep(for: .milliseconds(2)) }
        await local.configure(plants: []); await provider.release()
        do { _ = try await next.value; XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, .notFound) }
    }
}
