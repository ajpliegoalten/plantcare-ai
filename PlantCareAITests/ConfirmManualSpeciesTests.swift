import XCTest
@testable import PlantCareAI

final class ConfirmManualSpeciesTests: XCTestCase {
    func testTrimsOnlyExtremesAndHasHonestManualSource() throws {
        let photo = UUID()
        for name in ["Ficus lyrata", "Potus", "Árbol  común\ncon interior", "100% mío!", String(repeating: "Á", count: 1200)] {
            let identity = try ConfirmManualSpecies().execute(photoID: photo, name: " \n\t" + name + "\n ")
            XCTAssertEqual(identity, ConfirmedDraftIdentity(photoID: photo, source: .manual(name: name)))
            XCTAssertEqual(identity.manualName, name)
            XCTAssertNil(identity.commonName); XCTAssertNil(identity.scientificName)
            XCTAssertNil(identity.resultID); XCTAssertNil(identity.proposal)
        }
    }

    func testEmptyWhitespaceAndNewlinesRejected() {
        for name in ["", " ", "\n\r\t", "\u{2003}\u{00A0}"] {
            XCTAssertThrowsError(try ConfirmManualSpecies().execute(photoID: UUID(), name: name)) {
                XCTAssertEqual($0 as? ConfirmManualSpeciesError, .emptyName)
            }
        }
    }
}
