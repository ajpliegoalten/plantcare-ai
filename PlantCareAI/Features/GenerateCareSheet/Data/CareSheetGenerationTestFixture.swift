#if DEBUG && targetEnvironment(simulator)
import Foundation

@MainActor
final class CareSheetGenerationTestFixture: CareSheetGenerationRepository {
    private(set) var invocations = 0
    let mode: String
    init(mode: String) { self.mode = mode }

    func generate(identity: ConfirmedDraftIdentity) async throws -> CareSheet {
        invocations += 1
        let invocation = invocations
        if mode == "retained-error" { throw CareSheetGenerationError.network }
        if mode == "waiting" {
            // Deliberately uncooperative response tests the draft token, not just Task cancellation.
            try? await Task.sleep(for: .seconds(20))
        }
        if mode == "error" && invocation == 1 { throw CareSheetGenerationError.network }
        if mode == "incomplete" && invocation == 1 {
            return CareSheet(light: "", watering: "Riego", humidity: "Humedad", temperature: "Temperatura", substrate: "Sustrato", fertilizer: "Abonado")
        }
        let name = identity.manualName ?? identity.scientificName ?? identity.commonName ?? ""
        func text(_ field: String) -> String {
            let text = "\(field) para \(name). Comprueba las condiciones de tu planta."
            return mode == "long" ? String((text + String(repeating: " Consejo orientativo según el sustrato.", count: 30)).prefix(999)) + "." : text
        }
        return CareSheet(light: text("Luz"), watering: text("Riego"), humidity: text("Humedad"), temperature: text("Temperatura"), substrate: text("Sustrato"), fertilizer: text("Abonado"))
    }
}
#endif
