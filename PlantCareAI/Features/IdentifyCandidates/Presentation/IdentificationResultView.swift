import SwiftUI

struct IdentificationResultView: View {
    let result: IdentificationResult
    let selected: SpeciesProposalSelection?
    let canSelect: Bool
    let canConfirm: Bool
    let select: (SpeciesProposalSelection) -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(result.outcome == .proposals ? "identifyCandidates.proposal" : "identifyCandidates.insufficient")
                .font(.headline)
                .accessibilityIdentifier("identificationResultHeading")
            if let primary = result.primary {
                Text("confirmSpecies.couldBe").font(.title3)
                candidate(primary, selection: .primary, badge: "confirmSpecies.primary", identifier: "speciesProposal-primary")
            }
            if !result.alternatives.isEmpty {
                Text("identifyCandidates.alternatives").font(.headline)
                ForEach(Array(result.alternatives.enumerated()), id: \.offset) { index, value in
                    candidate(value, selection: .alternative(index: index), badge: "confirmSpecies.alternative", identifier: "speciesProposal-alternative-\(index)")
                }
            }
            Text(result.uncertainty).accessibilityIdentifier("identificationUncertainty")
            Text("identifyCandidates.notConfirmed").font(.callout)
            if result.outcome == .insufficientEvidence { Text("identifyCandidates.changePhoto") }
            if result.outcome == .proposals {
                Button(action: confirm) {
                    Text("confirmSpecies.confirm").frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(canConfirm ? Color("Surface") : Color("TextSecondary"))
                }
                .buttonStyle(.borderedProminent).disabled(!canConfirm)
                .accessibilityIdentifier("confirmSpecies")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color("TextPrimary"))
        .multilineTextAlignment(.leading)
        .padding(16).background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
    }

    private func candidate(_ value: SpeciesCandidate, selection: SpeciesProposalSelection,
                           badge: LocalizedStringKey, identifier: String) -> some View {
        let isSelected = selected == selection
        return Button { select(selection) } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(badge).font(.callout).foregroundStyle(Color("TextSecondary"))
                if let scientific = value.scientificName {
                    Text(scientific).font(.title3.weight(.semibold))
                }
                if let common = value.commonName, common != value.scientificName {
                    Text(common).font(.body)
                }
                if isSelected { Label("confirmSpecies.selected", systemImage: "checkmark.circle.fill") }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .foregroundStyle(Color("TextPrimary"))
            .padding(16).background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color("Primary") : Color("Outline"), lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain).disabled(!canSelect)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
