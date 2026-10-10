#if DEBUG && targetEnvironment(simulator)
import Foundation

/// Explicit, isolated E2E fixture. Never a production fallback, never HTTP evidence.
@MainActor
final class IdentificationCandidatesTestFixture {
    private(set) var invocations = 0
    let mode: String
    init(mode: String) { self.mode = mode }

    func identify(_ photo: IdentificationPhoto) async throws -> IdentificationContinuationResult {
        invocations += 1
        try await Task.sleep(for: .seconds(mode == "slow" ? 30 : 1))
        if mode == "error" && invocations == 1 { throw SpeciesIdentificationError.rateLimited }
        if mode == "insufficient" {
            return .completed(IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [], uncertainty: "No se distinguen hojas ni otros rasgos suficientes para proponer una especie."))
        }
        let commonName = mode == "long" ? String(String(repeating: "Costilla de Adán de hojas amplias ", count: 5).prefix(160)) : "Costilla de Adán"
        let uncertainty = mode == "long" ? String(String(repeating: "La imagen sugiere esta posibilidad, pero no permite confirmar la especie. Comprueba las hojas y el tallo antes de decidir. ", count: 9).prefix(1000)) : "Las hojas sugieren esta posibilidad, pero una sola foto no permite confirmarla. Comprueba la forma de las hojas y el tallo."
        let alternatives: [SpeciesCandidate]
        if mode == "max-alternatives" {
            // Deliberately synthetic names: exercise the maximum, not botanical accuracy.
            alternatives = (1...3).map {
                SpeciesCandidate(commonName: "Alternativa de prueba \($0)", scientificName: "Species fixture \($0)")
            }
        } else {
            alternatives = mode == "no-alternatives" ? [] : [SpeciesCandidate(commonName: "Filodendro", scientificName: "Philodendron bipinnatifidum")]
        }
        return .completed(IdentificationResult(outcome: .proposals,
            primary: SpeciesCandidate(commonName: commonName, scientificName: "Monstera deliciosa"),
            alternatives: alternatives,
            uncertainty: uncertainty))
    }
}
#endif
