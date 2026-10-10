import SwiftUI

struct IdentificationResultView: View {
    let result: IdentificationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(result.outcome == .proposals ? "identifyCandidates.proposal" : "identifyCandidates.insufficient")
                .font(.headline)
                .accessibilityIdentifier("identificationResultHeading")
            if let primary = result.primary { candidate(primary) }
            if !result.alternatives.isEmpty {
                Text("identifyCandidates.alternatives").font(.headline)
                ForEach(Array(result.alternatives.enumerated()), id: \.offset) { _, value in candidate(value) }
            }
            Text(result.uncertainty).accessibilityIdentifier("identificationUncertainty")
            Text("identifyCandidates.notConfirmed").font(.callout)
            if result.outcome == .insufficientEvidence { Text("identifyCandidates.changePhoto") }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color("TextPrimary"))
        .multilineTextAlignment(.leading)
        .padding(16).background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
    }

    private func candidate(_ value: SpeciesCandidate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value.displayName).font(.body.weight(.semibold))
            if let common = value.commonName, let scientific = value.scientificName, common != scientific {
                Text(scientific).font(.callout).foregroundStyle(Color("TextSecondary"))
            }
        }
    }
}
