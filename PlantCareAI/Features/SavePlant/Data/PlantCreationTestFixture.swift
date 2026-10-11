#if DEBUG && targetEnvironment(simulator)
import Foundation

final class PlantCreationTestFixture: @unchecked Sendable {
    private let lock = NSLock()
    private var attempts = 0
    private let mode: String
    init(mode: String) { self.mode = mode }
    func beforeCommit() throws {
        lock.lock(); attempts += 1; let attempt = attempts; lock.unlock()
        if mode == "waiting" { Thread.sleep(forTimeInterval: 15) }
        if mode == "error" && attempt == 1 { throw PlantStorageError.storage }
    }
}
#endif
