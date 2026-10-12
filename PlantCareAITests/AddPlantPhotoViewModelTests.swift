import XCTest
import UIKit
@testable import PlantCareAI

@MainActor
final class AddPlantPhotoViewModelTests: XCTestCase {
    private func model(_ repository: PhotoTestRepository, saved: @escaping @MainActor (PlantPhoto, UIImage) -> Void = { _, _ in }) -> AddPlantPhotoViewModel {
        AddPlantPhotoViewModel(plant: StorageTestFixture.plant(1), prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()),
            validate: LocalPreparedPlantPhotoValidator(), camera: CheckCameraAccess(access: PhotoCamera()),
            add: AddPlantPhoto(repository: repository), zone: { TimeZone(identifier: "Europe/Madrid")! }, onSaved: saved)
    }
    private func wait(_ predicate: () -> Bool) async {
        for _ in 0..<1000 { if predicate() { return }; try? await Task.sleep(for: .milliseconds(2)) }
        XCTFail("Timed out")
    }
    func testEmptyReplacementFailureCancelCloseAndLateSelection() async throws {
        let repository = PhotoTestRepository(); let vm = model(repository)
        XCTAssertFalse(vm.canSave); XCTAssertNil(vm.photo)
        vm.select { StorageTestFixture.photo(1) }; await wait { !vm.isLoading }
        let first = try XCTUnwrap(vm.photo); let date = vm.occurredAt
        vm.select { Data("broken".utf8) }; await wait { !vm.isLoading }
        XCTAssertEqual(vm.photo, first); XCTAssertEqual(vm.occurredAt, date)
        vm.select { nil }; await wait { !vm.isLoading }; XCTAssertEqual(vm.photo, first)
        vm.select { try? await Task.sleep(for: .milliseconds(100)); return StorageTestFixture.photo(2) }
        vm.close(); try await Task.sleep(for: .milliseconds(150)); XCTAssertNil(vm.photo); XCTAssertNil(vm.preview)
        let writes = await repository.writes; XCTAssertTrue(writes.isEmpty)
        let reopened = model(repository); XCTAssertNil(reopened.photo); XCTAssertEqual(reopened.state, .editing)
    }
    func testRetrySnapshotBytesAndEditingCreatesNewIntentionCallbackOnce() async throws {
        let repository = PhotoTestRepository(); await repository.setFail(true)
        var saved: [PlantPhoto] = []; let vm = model(repository) { photo, _ in saved.append(photo) }
        vm.select { StorageTestFixture.photo(1) }; await wait { !vm.isLoading }
        await vm.save(); guard case .error(.storage) = vm.state else { return XCTFail() }
        let first = await repository.writes[0]
        await repository.setFail(false); await vm.save(); await vm.save()
        let attempts = await repository.writes
        XCTAssertEqual(attempts.count, 2); XCTAssertEqual(attempts[0].0, attempts[1].0); XCTAssertEqual(attempts[0].1, attempts[1].1)
        XCTAssertEqual(saved, [first.0]); XCTAssertEqual(vm.state, .saved)
        let second = model(repository); second.select { StorageTestFixture.photo(1) }; await wait { !second.isLoading }
        await repository.setFail(true); await second.save()
        second.selectDate(second.occurredAt.addingTimeInterval(-86400)); XCTAssertEqual(second.state, .editing)
        await repository.setFail(false); await second.save()
        let final = await repository.writes; XCTAssertNotEqual(final[2].0.id, final[3].0.id)
    }
    func testCommitLocksChangesDoubleTapAndLateTechnicalCancellation() async throws {
        let repository = PhotoTestRepository(); await repository.setBlocked(true)
        var callbacks = 0; let vm = model(repository) { _, _ in callbacks += 1 }
        vm.select { StorageTestFixture.photo(1) }; await wait { !vm.isLoading }
        let photo = vm.photo, date = vm.occurredAt
        let save = Task { await vm.save() }; await wait { vm.isSaving }
        XCTAssertFalse(vm.canClose); XCTAssertFalse(vm.canSave)
        vm.close(); vm.selectDate(date.addingTimeInterval(-86400)); vm.select { StorageTestFixture.photo(2) }; await vm.save()
        XCTAssertEqual(vm.photo, photo); XCTAssertEqual(vm.occurredAt, date)
        save.cancel(); await repository.release(); await save.value
        XCTAssertEqual(vm.state, .saved); XCTAssertEqual(callbacks, 1)
        let writes = await repository.writes; XCTAssertEqual(writes.count, 1)
    }
    func testClosedDuringPrevalidationCannotDispatchWrite() async throws {
        let repository = PhotoTestRepository(), validator = PhotoValidationGate()
        let vm = AddPlantPhotoViewModel(plant: StorageTestFixture.plant(1),
            prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()), validate: validator,
            camera: CheckCameraAccess(access: PhotoCamera()), add: AddPlantPhoto(repository: repository),
            zone: { TimeZone(identifier: "Europe/Madrid")! }, onSaved: { _, _ in XCTFail("Closed session callback") })
        vm.select { StorageTestFixture.photo(1) }; await wait { !vm.isLoading }
        let save = Task { await vm.save() }; await validator.wait()
        XCTAssertEqual(vm.state, .validating); XCTAssertTrue(vm.canClose)
        vm.close(); await validator.release(); await save.value
        let writes = await repository.writes; XCTAssertTrue(writes.isEmpty)
    }
    func testRetryPreservesOriginAndCreatedAtAcrossZoneAndMidnight() async throws {
        let repository = PhotoTestRepository(); await repository.setFail(true)
        var clock = Date(timeIntervalSince1970: 1_700_000_000)
        var zone = TimeZone(identifier: "Europe/Madrid")!
        let vm = AddPlantPhotoViewModel(plant: StorageTestFixture.plant(1),
            prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()), validate: LocalPreparedPlantPhotoValidator(),
            camera: CheckCameraAccess(access: PhotoCamera()), add: AddPlantPhoto(repository: repository), now: { clock }, zone: { zone }, onSaved: { _, _ in })
        vm.select { StorageTestFixture.photo(1) }; await wait { !vm.isLoading }; await vm.save()
        clock = clock.addingTimeInterval(2 * 86400); zone = TimeZone(identifier: "America/Los_Angeles")!
        vm.refreshDisplayZone(); await repository.setFail(false); await vm.save()
        let writes = await repository.writes
        XCTAssertEqual(writes.count, 2); XCTAssertEqual(writes[0].0, writes[1].0)
        XCTAssertEqual(writes[1].0.timeZoneIdentifier, "Europe/Madrid")
    }
}

private actor PhotoValidationGate: PreparedPlantPhotoValidating {
    var continuation: CheckedContinuation<Void, Never>?
    func validate(_ photo: IdentificationPhoto) async throws { await withCheckedContinuation { continuation = $0 } }
    func wait() async { while continuation == nil { await Task.yield() } }
    func release() { continuation?.resume(); continuation = nil }
}

actor PhotoTestRepository: PlantPhotoRepository {
    var writes: [(PlantPhoto, Data)] = []
    var photos: [PlantPhoto] = []
    var reads: [UUID] = []
    var fail = false
    var blocked = false
    var continuation: CheckedContinuation<Void, Never>?
    func setFail(_ value: Bool) { fail = value }
    func setBlocked(_ value: Bool) { blocked = value }
    func release() { continuation?.resume(); continuation = nil }
    func savePhoto(_ photo: PlantPhoto, jpeg: Data) async throws -> PlantPhoto {
        writes.append((photo, jpeg))
        if blocked { await withCheckedContinuation { continuation = $0 } }
        if fail { throw PlantPhotoError.storage }
        photos.removeAll { $0.id == photo.id }; photos.append(photo); return photo
    }
    func loadPhotos(for plantID: UUID) async throws -> [PlantPhoto] {
        if fail { throw PlantPhotoError.storage }; return photos.filter { $0.plantID == plantID }
    }
    func loadPhoto(id: UUID, for plantID: UUID) async throws -> Data {
        reads.append(id)
        if fail { throw PlantPhotoError.photoMissing }
        return StorageTestFixture.photo(2)
    }
}

private struct PhotoCamera: CameraAccess {
    func isAvailable() async -> Bool { false }
    func authorization() async -> CameraAuthorization { .denied }
    func requestAuthorization() async -> Bool { false }
}
