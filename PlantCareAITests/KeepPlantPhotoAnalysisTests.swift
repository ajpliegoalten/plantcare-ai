import XCTest
@testable import PlantCareAI

final class KeepPlantPhotoAnalysisTests: XCTestCase {
    static func snapshot(plant: Plant = StorageTestFixture.plant(1), source: PlantPhotoDescriptor? = nil,
                         id: UUID = UUID(), content: PlantPhotoAnalysisContent = BuildPlantAnalysisContextTests.content) -> PlantPhotoAnalysisAcceptance {
        let descriptor = source ?? .init(id: .initial(plant.id), date: plant.createdAt, createdAt: plant.createdAt)
        return .init(record: .init(id: id, plantID: plant.id, identity: descriptor.id, photoDate: descriptor.date,
            queriedAt: Date(timeIntervalSince1970: 2_000_000), revision: 1,
            acceptedAt: Date(timeIntervalSince1970: 3_000_000), content: content), source: descriptor)
    }

    func testUsefulInitialAdditionalRetroactiveAndSeparateDates() throws {
        let first = Self.snapshot()
        try KeepPlantPhotoAnalysis.validate(first)
        let additional = Self.snapshot(source: .init(id: .additional(UUID()), date: Date(timeIntervalSince1970: -100), createdAt: Date()))
        try KeepPlantPhotoAnalysis.validate(additional)
        XCTAssertNotEqual(first.record.photoDate, first.record.queriedAt)
        XCTAssertNotEqual(first.record.queriedAt, first.record.acceptedAt)
    }

    func testRejectsInsufficientInvalidContentForeignInitialAndNonFiniteDateBeforeDispatch() async {
        let store = AcceptanceSpy()
        let use = KeepPlantPhotoAnalysis(repository: store)
        let invalid = [Self.snapshot(content: .init(outcome: .insufficientEvidence, observations: ["No evidence"], possibleCauses: [], checks: [])),
            Self.snapshot(content: .init(outcome: .analysis, observations: [], possibleCauses: [], checks: ["Check"])),
            Self.snapshot(source: .init(id: .initial(UUID()), date: Date(), createdAt: Date())),
            Self.snapshot(source: .init(id: .additional(UUID()), date: Date(timeIntervalSince1970: .infinity), createdAt: Date()))]
        for snapshot in invalid {
            do { _ = try await use.execute(snapshot); XCTFail("invalid accepted") }
            catch { XCTAssertEqual(error as? KeepPlantPhotoAnalysisError, .validation) }
        }
        let calls = await store.snapshots; XCTAssertTrue(calls.isEmpty)
    }

    func testLiteralUnicodePayloadIsNotCanonicalEquality() {
        let id = UUID()
        let a = Self.snapshot(id: id, content: .init(outcome: .analysis, observations: ["é"], possibleCauses: [], checks: ["Check"]))
        let b = Self.snapshot(id: id, content: .init(outcome: .analysis, observations: ["e\u{301}"], possibleCauses: [], checks: ["Check"]))
        XCTAssertNotEqual(a, b)
    }
}

actor AcceptanceSpy: KeepPlantPhotoAnalysisUseCase, PlantPhotoAnalysisStoring {
    var snapshots: [PlantPhotoAnalysisAcceptance] = []
    var failure: KeepPlantPhotoAnalysisError?
    var continuation: CheckedContinuation<Void, Never>?
    var hold = false
    func configure(failure: KeepPlantPhotoAnalysisError? = nil, hold: Bool = false) { self.failure = failure; self.hold = hold }
    func release() { hold = false; continuation?.resume(); continuation = nil }
    func execute(_ snapshot: PlantPhotoAnalysisAcceptance) async throws -> SavedPlantPhotoAnalysis { try await saveAccepted(snapshot) }
    func saveAccepted(_ snapshot: PlantPhotoAnalysisAcceptance) async throws -> SavedPlantPhotoAnalysis {
        snapshots.append(snapshot)
        if hold { await withCheckedContinuation { continuation = $0 } }
        if let failure { throw failure }
        return snapshot.record
    }
    func loadSavedAnalyses(for plantID: UUID) async throws -> [SavedPlantPhotoAnalysis] { snapshots.map(\.record).filter { $0.plantID == plantID } }
}

actor SavedAnalysisReadGate: SavedPlantPhotoAnalysisReading {
    private var requests: [Int: CheckedContinuation<[SavedPlantPhotoAnalysis], Error>] = [:]
    private(set) var count = 0
    func loadSavedAnalyses(for plantID: UUID) async throws -> [SavedPlantPhotoAnalysis] {
        count += 1; let token = count
        return try await withCheckedThrowingContinuation { requests[token] = $0 }
    }
    func complete(_ token: Int, records: [SavedPlantPhotoAnalysis] = [], fail: Bool = false) {
        guard let request = requests.removeValue(forKey: token) else { return }
        if fail { request.resume(throwing: KeepPlantPhotoAnalysisError.readFailure) } else { request.resume(returning: records) }
    }
}

@MainActor
final class KeepAnalysisEligibilityTests: XCTestCase {
    private func wait(_ condition: @escaping () -> Bool) async {
        for _ in 0..<500 { if condition() { return }; try? await Task.sleep(for: .milliseconds(10)) }
        XCTFail("eligibility state timeout")
    }
    private func registered(_ gate: SavedAnalysisReadGate, count: Int) async {
        for _ in 0..<500 { if await gate.count >= count { return }; try? await Task.sleep(for: .milliseconds(10)) }
        XCTFail("reader registration timeout")
    }
    func testUnknownFailedAndLateEmptyNeverEnableDefinitiveAndRefreshPreservesSelectionCache() async throws {
        let local = AnalysisLocalSpy(), gate = SavedAnalysisReadGate()
        let plant = try await local.loadPlants()[0]
        let vm = PlantPhotoPagerViewModel(plant: plant, loadMetadata: .init(repository: local),
            loadAdditional: .init(repository: local), loadInitial: .init(repository: local), analysisReader: gate)
        XCTAssertFalse(vm.canAnalyze); vm.appear(); await registered(gate, count: 1)
        await gate.complete(1, fail: true)
        await wait { if case .failed = vm.analysisState { return true }; return false }
        XCTAssertFalse(vm.canAnalyze)
        vm.refreshAnalyses(); await registered(gate, count: 2)
        vm.refreshAnalyses(); await registered(gate, count: 3)
        let record = KeepPlantPhotoAnalysisTests.snapshot(plant: plant).record
        await gate.complete(3, records: [record])
        await wait { if case .loaded = vm.analysisState { return true }; return false }
        await gate.complete(2); await Task.yield(); XCTAssertFalse(vm.canAnalyze)
        let selected = vm.selected, count = vm.cachedImageCount
        vm.refreshAnalyses(); await registered(gate, count: 4); await gate.complete(4, records: [record])
        await wait { if case .loaded = vm.analysisState { return true }; return false }
        XCTAssertEqual(vm.selected, selected); XCTAssertEqual(vm.cachedImageCount, count)
        vm.disappear(preservingSelection: true); XCTAssertFalse(vm.canAnalyze)
    }
}
