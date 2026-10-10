import Foundation

struct SpeciesCandidate: Equatable, Sendable, Decodable {
    let commonName: String?
    let scientificName: String?

    var displayName: String { commonName ?? scientificName ?? "" }
}

/// A proposal, never a confirmed identity or a persisted plant.
struct IdentificationResult: Equatable, Sendable, Decodable {
    enum Outcome: String, Decodable, Sendable { case proposals, insufficientEvidence }
    let outcome: Outcome
    let primary: SpeciesCandidate?
    let alternatives: [SpeciesCandidate]
    let uncertainty: String

    func validated() throws -> Self {
        func validText(_ text: String, limit: Int) -> Bool {
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= limit &&
            !text.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) && $0 != "\n" } &&
            !text.contains("%")
        }
        func validCandidate(_ candidate: SpeciesCandidate) -> Bool {
            let names = [candidate.commonName, candidate.scientificName].compactMap { $0 }
            return !names.isEmpty && names.allSatisfy { validText($0, limit: 160) }
        }
        guard validText(uncertainty, limit: 1000), alternatives.count <= 3 else {
            throw SpeciesIdentificationError.invalidResponse
        }
        switch outcome {
        case .insufficientEvidence:
            guard primary == nil, alternatives.isEmpty else { throw SpeciesIdentificationError.invalidResponse }
        case .proposals:
            guard let primary, validCandidate(primary), alternatives.allSatisfy(validCandidate) else {
                throw SpeciesIdentificationError.invalidResponse
            }
            let candidates = [primary] + alternatives
            let names = candidates.map { ($0.scientificName ?? $0.commonName ?? "").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es")).trimmingCharacters(in: .whitespacesAndNewlines) }
            guard Set(names).count == names.count else { throw SpeciesIdentificationError.invalidResponse }
        }
        return self
    }
}

enum IdentificationContinuationResult { case unavailable, completed(IdentificationResult) }
