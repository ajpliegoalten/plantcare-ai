import XCTest
@testable import PlantCareAI

private struct IdentificationRepositoryDouble: SpeciesIdentificationRepository {
    let result: IdentificationResult
    func identify(photo: IdentificationPhoto) async throws -> IdentificationResult { result }
}

final class IdentifyCandidatesTests: XCTestCase {
    private let primary = SpeciesCandidate(commonName: "Monstera", scientificName: "Monstera deliciosa")

    func testProposalsWithoutAlternativesAndInsufficientEvidenceAreDistinct() async throws {
        for result in [IdentificationResult(outcome: .proposals, primary: primary, alternatives: [], uncertainty: "Podría ser esta especie."),
                       IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [], uncertainty: "No hay rasgos suficientes.")] {
            let useCase = IdentifyCandidates(repository: IdentificationRepositoryDouble(result: result))
            let actual = try await useCase.execute(photo: IdentificationPhoto(id: UUID(), jpeg: Data([1]), width: 1, height: 1))
            XCTAssertEqual(actual, result)
        }
    }

    func testInvalidInvariantsRejectRatherThanInventSuccess() {
        let invalid = [
            IdentificationResult(outcome: .proposals, primary: nil, alternatives: [], uncertainty: "Duda"),
            IdentificationResult(outcome: .insufficientEvidence, primary: primary, alternatives: [], uncertainty: "Duda"),
            IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [primary], uncertainty: "Duda"),
            IdentificationResult(outcome: .proposals, primary: SpeciesCandidate(commonName: " ", scientificName: nil), alternatives: [], uncertainty: "Duda"),
            IdentificationResult(outcome: .proposals, primary: primary, alternatives: [primary], uncertainty: "Duda"),
            IdentificationResult(outcome: .proposals, primary: primary, alternatives: [], uncertainty: "99%"),
            IdentificationResult(outcome: .proposals, primary: primary, alternatives: [], uncertainty: String(repeating: "a", count: 1001)),
            IdentificationResult(outcome: .proposals, primary: SpeciesCandidate(commonName: String(repeating: "a", count: 161), scientificName: nil), alternatives: [], uncertainty: "Duda")
        ]
        for result in invalid { XCTAssertThrowsError(try result.validated()) }
    }

    func testPhotoLimitAndCancellation() async {
        let useCase = IdentifyCandidates(repository: IdentificationRepositoryDouble(result: IdentificationResult(outcome: .proposals, primary: primary, alternatives: [], uncertainty: "Duda")))
        for data in [Data(), Data(repeating: 1, count: 5 * 1024 * 1024 + 1)] {
            do { _ = try await useCase.execute(photo: IdentificationPhoto(id: UUID(), jpeg: data, width: 1, height: 1)); XCTFail() }
            catch { XCTAssertEqual(error as? SpeciesIdentificationError, .invalidResponse) }
        }
        let task = Task { try await Task.sleep(for: .seconds(1)); return try await useCase.execute(photo: IdentificationPhoto(id: UUID(), jpeg: Data([1]), width: 1, height: 1)) }
        task.cancel()
        do { _ = try await task.value; XCTFail() } catch { XCTAssertTrue(error is CancellationError) }
    }
}
