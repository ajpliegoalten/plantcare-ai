import XCTest
@testable import PlantCareAI

actor CareRepositoryDouble: CareSheetGenerationRepository {
    private(set) var identities: [ConfirmedDraftIdentity] = []
    var sheet = CareSheet(light: " Luz ", watering: "Riego", humidity: "Humedad", temperature: "Temperatura", substrate: "Sustrato", fertilizer: "Abonado")
    var error: CareSheetGenerationError?
    var held = false
    var continuation: CheckedContinuation<CareSheet, Never>?
    func configure(sheet: CareSheet? = nil, error: CareSheetGenerationError? = nil, held: Bool = false) {
        if let sheet { self.sheet = sheet }
        self.error = error; self.held = held
    }
    func generate(identity: ConfirmedDraftIdentity) async throws -> CareSheet {
        identities.append(identity)
        if held { return await withCheckedContinuation { continuation = $0 } }
        if let error { throw error }
        return sheet
    }
    func release() { continuation?.resume(returning: sheet); continuation = nil }
}

final class GenerateCareSheetTests: XCTestCase {
    func testInputBindingNamesLimitAndZeroIOOnInvalidInput() async throws {
        let repository = CareRepositoryDouble(), useCase = GenerateCareSheet(repository: CareRepositoryDouble())
        let photo = UUID()
        for name in ["", " \n ", String(repeating: "a", count: 2001)] {
            do {
                _ = try await GenerateCareSheet(repository: repository).execute(identity: ConfirmedDraftIdentity(photoID: photo, source: .manual(name: name)), photoID: photo)
                XCTFail()
            } catch { XCTAssertEqual(error as? CareSheetGenerationError, .invalidInput) }
        }
        do { _ = try await useCase.execute(identity: ConfirmedDraftIdentity(photoID: photo, source: .manual(name: "Ficus")), photoID: UUID()); XCTFail() }
        catch { XCTAssertEqual(error as? CareSheetGenerationError, .invalidInput) }
        let calls = await repository.identities; XCTAssertTrue(calls.isEmpty)
        let name = String(repeating: "á", count: 2000)
        let identity = ConfirmedDraftIdentity(photoID: photo, source: .manual(name: name))
        let sheet = try await GenerateCareSheet(repository: repository).execute(identity: identity, photoID: photo)
        XCTAssertEqual(sheet.light, "Luz")
        let inputs = await repository.identities; XCTAssertEqual(inputs, [identity])
    }

    func testAllSixFieldsMustBeCompleteAndBounded() throws {
        for invalid in ["", " \n ", String(repeating: "x", count: 1001)] {
            for index in 0..<6 {
                var fields = Array(repeating: "Consejo", count: 6); fields[index] = invalid
                XCTAssertThrowsError(try GenerateCareSheet.validate(CareSheet(light: fields[0], watering: fields[1], humidity: fields[2], temperature: fields[3], substrate: fields[4], fertilizer: fields[5])))
            }
        }
        let text = String(repeating: "x", count: 1000)
        XCTAssertNoThrow(try GenerateCareSheet.validate(CareSheet(light: text, watering: text, humidity: text, temperature: text, substrate: text, fertilizer: text)))
    }
}
