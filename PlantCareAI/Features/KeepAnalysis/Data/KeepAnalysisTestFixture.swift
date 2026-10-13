#if DEBUG && targetEnvironment(simulator)
import Foundation

final class KeepAnalysisTestFixture: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0
    let mode: String
    init(mode: String) { self.mode = mode }
    func beforeCommit() throws {
        let call = lock.withLock { calls += 1; return calls }
        if mode == "busy" { Thread.sleep(forTimeInterval: 12) }
        if mode == "failOnce", call == 1 { throw KeepPlantPhotoAnalysisError.storage }
    }
}
#endif
