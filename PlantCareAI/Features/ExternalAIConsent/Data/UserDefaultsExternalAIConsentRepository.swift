import Foundation
import CoreFoundation

actor UserDefaultsExternalAIConsentRepository: ExternalAIConsentRepository {
    private let defaults: UserDefaults
    static let key = "externalAIConsent.acceptance"

    init(defaults: UserDefaults) { self.defaults = defaults }

    func acceptance() async throws -> ExternalAIConsent? {
        try Task.checkCancellation()
        guard let value = defaults.object(forKey: Self.key) as? [String: Any],
              Set(value.keys) == ["recipient", "noticeVersion"],
              let recipient = value["recipient"] as? String, !recipient.isEmpty,
              let version = value["noticeVersion"] as? NSNumber,
              CFGetTypeID(version) != CFBooleanGetTypeID(),
              version.doubleValue == Double(version.intValue), version.intValue > 0 else { return nil }
        return ExternalAIConsent(recipient: recipient, noticeVersion: version.intValue)
    }

    func record(_ consent: ExternalAIConsent) async throws {
        try Task.checkCancellation()
        // Foundation considers NSNumber(true) == NSNumber(1). Remove first so an
        // invalid Boolean version cannot survive a dictionary equality shortcut.
        defaults.removeObject(forKey: Self.key)
        defaults.set(["recipient": consent.recipient, "noticeVersion": consent.noticeVersion], forKey: Self.key)
        // UserDefaults is a preference, not a synchronous disk transaction.
    }
}
