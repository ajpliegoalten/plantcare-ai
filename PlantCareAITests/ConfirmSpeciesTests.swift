import XCTest
@testable import PlantCareAI

final class ConfirmSpeciesTests: XCTestCase {
    private let primary = SpeciesCandidate(commonName: "Costilla de Adán", scientificName: "Monstera deliciosa")
    private func result(_ candidate: SpeciesCandidate? = nil) -> IdentificationResult {
        IdentificationResult(outcome: .proposals, primary: primary,
                             alternatives: candidate.map { [$0] } ?? [], uncertainty: "Podría ser otra especie.")
    }

    func testPrimaryAndAlternativesCopyExactNamesAndTokens() throws {
        let photo = UUID(), revision = UUID()
        let identity = try ConfirmSpecies().execute(photoID: photo, resultID: revision, result: result(), selection: .primary)
        XCTAssertEqual(identity, ConfirmedDraftIdentity(photoID: photo, source: .aiProposal(resultID: revision,
            selection: .primary, commonName: primary.commonName, scientificName: primary.scientificName)))
        for candidate in [SpeciesCandidate(commonName: "Solo común", scientificName: nil),
                          SpeciesCandidate(commonName: nil, scientificName: "Solo científico"),
                          SpeciesCandidate(commonName: " Nombre literal ", scientificName: "Nombre distinto")] {
            let selected = try ConfirmSpecies().execute(photoID: photo, resultID: revision, result: result(candidate), selection: .alternative(index: 0))
            XCTAssertEqual(selected.commonName, candidate.commonName)
            XCTAssertEqual(selected.scientificName, candidate.scientificName)
            XCTAssertEqual(selected.photoID, photo); XCTAssertEqual(selected.resultID, revision)
            XCTAssertEqual(selected.proposal, .alternative(index: 0))
        }
    }

    func testRejectsInvalidMembershipAndResults() {
        for index in [-1, 0, 3, Int.max] {
            XCTAssertThrowsError(try ConfirmSpecies().execute(photoID: UUID(), resultID: UUID(), result: result(), selection: .alternative(index: index))) {
                XCTAssertEqual($0 as? ConfirmSpeciesError, .invalidSelection)
            }
        }
        for invalid in [IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [], uncertainty: "No hay evidencia."),
                        IdentificationResult(outcome: .proposals, primary: nil, alternatives: [], uncertainty: "Duda"),
                        IdentificationResult(outcome: .proposals, primary: primary, alternatives: [primary], uncertainty: "Duda"),
                        IdentificationResult(outcome: .proposals, primary: primary, alternatives: [], uncertainty: "100% seguro")] {
            XCTAssertThrowsError(try ConfirmSpecies().execute(photoID: UUID(), resultID: UUID(), result: invalid, selection: .primary)) {
                XCTAssertEqual($0 as? ConfirmSpeciesError, .invalidResult)
            }
        }
    }
}
