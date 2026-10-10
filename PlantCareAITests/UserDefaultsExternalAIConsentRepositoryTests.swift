import XCTest
@testable import PlantCareAI

final class UserDefaultsExternalAIConsentRepositoryTests: XCTestCase {
    func testIsolatedPreferenceStrictValidationAndNewInstance() async throws {
        let name = "ConsentTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let repository = UserDefaultsExternalAIConsentRepository(defaults: defaults)
        let absent = try await repository.acceptance(); XCTAssertNil(absent)
        let invalidValues: [Any] = ["yes", ["recipient": "x"], ["recipient": "x", "noticeVersion": true], ["recipient": "x", "noticeVersion": 1.5], ["recipient": "", "noticeVersion": 1], ["recipient": "x", "noticeVersion": 1, "extra": 2]]
        for invalid in invalidValues {
            defaults.set(invalid, forKey: UserDefaultsExternalAIConsentRepository.key)
            let result = try await repository.acceptance(); XCTAssertNil(result)
        }
        defaults.set(["recipient": ExternalAIConsent.current.recipient, "noticeVersion": true], forKey: UserDefaultsExternalAIConsentRepository.key)
        try await repository.record(.current)
        let reopened = UserDefaultsExternalAIConsentRepository(defaults: try XCTUnwrap(UserDefaults(suiteName: name)))
        let saved = try await reopened.acceptance(); XCTAssertEqual(saved, .current)
        XCTAssertEqual(Set(defaults.persistentDomain(forName: name)!.keys), [UserDefaultsExternalAIConsentRepository.key])
    }
}
