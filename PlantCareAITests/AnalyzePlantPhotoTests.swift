import XCTest
@testable import PlantCareAI

actor AnalysisLocalSpy: PlantRepository, CareEventRepository, PlantPhotoRepository, AcceptedPlantPhotoAnalysisReading {
    var plants = [BuildPlantAnalysisContextTests.plant(), BuildPlantAnalysisContextTests.plant(id: UUID())]
    var additional: [PlantPhoto] = []
    var acceptedRecords: [AcceptedPlantPhotoAnalysis] = []
    var failCare = false; var failAccepted = false
    var events: [CareEvent] = []
    var reads: [PlantPhotoIdentity] = []; var writes = 0
    func loadPlants() async throws -> [Plant] { plants }
    func loadInitialPhoto(for id: UUID) async throws -> Data { reads.append(.initial(id)); return StorageTestFixture.photo(1) }
    func savePlant(_ plant: Plant, initialPhoto: Data) async throws { writes += 1 }
    func updatePlant(id: UUID, name: String, location: String?) async throws -> Plant { writes += 1; return plants[0] }
    func loadCareEvents(for plantID: UUID) async throws -> [CareEvent] { if failCare { throw PlantPhotoAnalysisError.readFailure }; return events }
    func saveCareEvent(_ event: CareEvent) async throws -> CareEvent { writes += 1; return event }
    func loadPhotos(for plantID: UUID) async throws -> [PlantPhoto] { additional }
    func loadPhoto(id: UUID, for plantID: UUID) async throws -> Data { reads.append(.additional(id)); return StorageTestFixture.photo(2) }
    func savePhoto(_ photo: PlantPhoto, jpeg: Data) async throws -> PlantPhoto { writes += 1; return photo }
    func loadAccepted(for plantID: UUID) async throws -> [AcceptedPlantPhotoAnalysis] { if failAccepted { throw PlantPhotoAnalysisError.readFailure }; return acceptedRecords }
    func setAccepted(_ value: [AcceptedPlantPhotoAnalysis]) { acceptedRecords = value }
    func setFailures(care: Bool = false, accepted: Bool = false) { failCare = care; failAccepted = accepted }
    func setPhotos(_ value: [PlantPhoto]) { additional = value }
    func setEvents(_ value: [CareEvent]) { events = value }
}

actor AnalysisProviderSpy: PlantPhotoAnalysisRepository {
    var calls: [(Data, PlantAnalysisContext)] = []
    var hold = false
    var continuation: CheckedContinuation<Void, Never>?
    func analyze(jpeg: Data, context: PlantAnalysisContext) async throws -> PlantPhotoAnalysisContent {
        calls.append((jpeg, context))
        if hold { await withCheckedContinuation { continuation = $0 } }
        return BuildPlantAnalysisContextTests.content
    }
    func setHold() { hold = true }
    func release() { hold = false; continuation?.resume(); continuation = nil }
}

final class AnalyzePlantPhotoTests: XCTestCase {
    func useCase(_ local: AnalysisLocalSpy, _ provider: AnalysisProviderSpy, reader: Bool = false) -> AnalyzePlantPhoto {
        AnalyzePlantPhoto(detail: LoadPlantDetail(repository: local), care: local, photos: local,
            initial: LoadInitialPlantPhoto(repository: local), repository: provider, gate: PlantPhotoAnalysisOperationGate(),
            acceptedReader: reader ? local : nil, validateJPEG: { try await OpenAICompatiblePlantPhotoAnalysisRepository.validateJPEG($0) })
    }
    func prepare(_ useCase: AnalyzePlantPhoto, _ id: UUID, _ identity: PlantPhotoIdentity) async throws -> PreparedPlantPhotoAnalysis {
        try await useCase.prepare(plantID: id, identity: identity, queriedAt: BuildPlantAnalysisContextTests.date(300), timeZone: TimeZone(secondsFromGMT: 0)!)
    }
    func testInitialAdditionalIsolationOnlySelectedJPEGAndNoWrites() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider)
        let plants = try await local.loadPlants(); let photoID = UUID()
        await local.setPhotos([.init(id: photoID, plantID: plants[1].id, occurredAt: BuildPlantAnalysisContextTests.date(1), createdAt: BuildPlantAnalysisContextTests.date(2), timeZoneIdentifier: "Africa/Abidjan", width: 640, height: 480)])
        let initial = try await prepare(use, plants[0].id, .initial(plants[0].id))
        let first = try await use.execute(initial)
        let additional = try await prepare(use, plants[1].id, .additional(photoID)); _ = try await use.execute(additional)
        XCTAssertEqual(first.identity, .initial(plants[0].id))
        let reads = await local.reads; XCTAssertEqual(reads, [.initial(plants[0].id), .additional(photoID)])
        let calls = await provider.calls; XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0].0, StorageTestFixture.photo(1)); XCTAssertEqual(calls[1].0, StorageTestFixture.photo(2))
        let writes = await local.writes; XCTAssertEqual(writes, 0)
    }
    func testForeignIdentitiesFailBeforeJPEGOrTransport() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider)
        let plants = try await local.loadPlants()
        for identity in [PlantPhotoIdentity.initial(plants[1].id), .additional(UUID())] {
            do { _ = try await prepare(use, plants[0].id, identity); XCTFail("foreign") } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .notFound) }
        }
        let reads = await local.reads; let calls = await provider.calls
        XCTAssertTrue(reads.isEmpty); XCTAssertTrue(calls.isEmpty)
    }
    func testDefinitiveGuardAtPreparationAndDispatchFutureReaderFailsClosed() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider, reader: true)
        let plant = try await local.loadPlants()[0]; let identity = PlantPhotoIdentity.initial(plant.id)
        let prepared = try await prepare(use, plant.id, identity)
        await local.setAccepted([.init(plantID: plant.id, identity: identity, photoDate: plant.createdAt, content: BuildPlantAnalysisContextTests.content)])
        do { _ = try await use.execute(prepared); XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .alreadyAnalyzed) }
        do { _ = try await prepare(use, plant.id, identity); XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .alreadyAnalyzed) }
        await local.setAccepted([]); await local.setFailures(accepted: true)
        do { _ = try await prepare(use, plant.id, identity); XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .readFailure) }
        let calls = await provider.calls; XCTAssertTrue(calls.isEmpty)
    }
    func testContextReadFailureDoesNotBecomeEmptyOrReadJPEG() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider)
        let plant = try await local.loadPlants()[0]; await local.setFailures(care: true)
        do { _ = try await prepare(use, plant.id, .initial(plant.id)); XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .readFailure) }
        let reads = await local.reads; XCTAssertTrue(reads.isEmpty)
    }
    func testSimultaneousGuardReleaseAndProvisionalDoesNotBlockNewIntention() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider)
        let plant = try await local.loadPlants()[0]; let value = try await prepare(use, plant.id, .initial(plant.id))
        await provider.setHold(); let first = Task { try await use.execute(value) }
        for _ in 0..<1000 { if await provider.continuation != nil { break }; await Task.yield() }
        let pending = await provider.continuation != nil; XCTAssertTrue(pending)
        do { _ = try await use.execute(value); XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .busy) }
        await provider.release(); _ = try await first.value; _ = try await use.execute(value)
        let calls = await provider.calls; XCTAssertEqual(calls.count, 2)
    }
    func testDeletedOriginAfterPreparationFailsBeforeSend() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider)
        let plant = try await local.loadPlants()[0]; let id = UUID()
        await local.setPhotos([.init(id: id, plantID: plant.id, occurredAt: BuildPlantAnalysisContextTests.date(1), createdAt: BuildPlantAnalysisContextTests.date(2), timeZoneIdentifier: "Africa/Abidjan", width: 640, height: 480)])
        let value = try await prepare(use, plant.id, .additional(id)); await local.setPhotos([])
        do { _ = try await use.execute(value); XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .notFound) }
        let calls = await provider.calls; XCTAssertTrue(calls.isEmpty)
    }
    func testOriginDeletedDuringProviderCannotPublishAndCancellationReleasesGate() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider)
        let plant = try await local.loadPlants()[0], id = UUID()
        let photo = PlantPhoto(id: id, plantID: plant.id, occurredAt: BuildPlantAnalysisContextTests.date(1), createdAt: BuildPlantAnalysisContextTests.date(2), timeZoneIdentifier: "Africa/Abidjan", width: 640, height: 480)
        await local.setPhotos([photo]); let value = try await prepare(use, plant.id, .additional(id))
        await provider.setHold(); let task = Task { try await use.execute(value) }
        for _ in 0..<1000 { if await provider.continuation != nil { break }; await Task.yield() }
        let pending = await provider.continuation != nil; XCTAssertTrue(pending)
        await local.setPhotos([]); await provider.release()
        do { _ = try await task.value; XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .notFound) }
        await local.setPhotos([photo]); _ = try await use.execute(value)
        await provider.setHold(); let cancelled = Task { try await use.execute(value) }
        for _ in 0..<1000 { if await provider.continuation != nil { break }; await Task.yield() }
        cancelled.cancel(); await provider.release()
        do { _ = try await cancelled.value; XCTFail() } catch { XCTAssertTrue(error is CancellationError) }
        _ = try await use.execute(value)
    }
    func testAbsentDefinitiveCapabilityIsExplicitAndDoesNotConsultFakeReader() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider)
        await local.setFailures(accepted: true)
        let plant = try await local.loadPlants()[0]
        let value = try await prepare(use, plant.id, .initial(plant.id))
        XCTAssertTrue(value.context.previousAcceptedInterpretations.isEmpty)
        _ = try await use.execute(value)
        let calls = await provider.calls; XCTAssertEqual(calls.count, 1)
    }
    func testTwoPlantsCarryOnlyOwnHumanNotesEvenWhenReaderReturnsMixedMetadata() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(); let use = useCase(local, provider)
        let plants = try await local.loadPlants()
        let events = plants.enumerated().map { index, plant in
            CareEvent(id: UUID(), plantID: plant.id, kind: .other, occurredAt: BuildPlantAnalysisContextTests.date(-1),
                note: index == 0 ? "SOLO CONTEXTO A" : "SOLO CONTEXTO B", createdAt: BuildPlantAnalysisContextTests.date(0), timeZoneIdentifier: "Africa/Abidjan")
        }
        await local.setEvents(events)
        for plant in plants {
            let prepared = try await prepare(use, plant.id, .initial(plant.id))
            _ = try await use.execute(prepared)
        }
        let calls = await provider.calls
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0].1.careEvents.map(\.note), ["SOLO CONTEXTO A"])
        XCTAssertEqual(calls[1].1.careEvents.map(\.note), ["SOLO CONTEXTO B"])
        XCTAssertFalse(String(decoding: try calls[0].1.encoded(), as: UTF8.self).contains("SOLO CONTEXTO B"))
        XCTAssertFalse(String(decoding: try calls[1].1.encoded(), as: UTF8.self).contains("SOLO CONTEXTO A"))
        let writes = await local.writes; XCTAssertEqual(writes, 0)
    }
}
