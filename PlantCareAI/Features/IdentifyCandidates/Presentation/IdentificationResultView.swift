import SwiftUI

struct IdentificationResultView<ManualOption: View>: View {
    let result: IdentificationResult
    let selected: SpeciesProposalSelection?
    let canSelect: Bool
    let select: (SpeciesProposalSelection) -> Void
    @ViewBuilder let manualOption: () -> ManualOption

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if result.outcome == .proposals {
                Text("identifyCandidates.proposal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("PrimaryAction"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier("identificationResultHeading")
            } else {
                Text("identifyCandidates.insufficient")
                    .font(.headline)
                    .accessibilityIdentifier("identificationResultHeading")
            }
            if let primary = result.primary {
                Text("confirmSpecies.couldBe")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                candidate(primary, selection: .primary, badge: "confirmSpecies.primary", identifier: "speciesProposal-primary")
            }
            VStack(alignment: .leading, spacing: 12) {
                Text(result.uncertainty)
                    .accessibilityIdentifier("identificationUncertainty")
                if result.outcome == .proposals {
                    Divider()
                    Label("identifyCandidates.notConfirmed", systemImage: "info.circle")
                        .font(.callout)
                        .foregroundStyle(Color("TextSecondary"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color("Background"), in: RoundedRectangle(cornerRadius: 16))
            if result.outcome == .insufficientEvidence { Text("identifyCandidates.changePhoto") }
            Text("identifyCandidates.alternatives").font(.headline)
            if !result.alternatives.isEmpty {
                ForEach(Array(result.alternatives.enumerated()), id: \.offset) { index, value in
                    candidate(value, selection: .alternative(index: index), badge: "confirmSpecies.alternative", identifier: "speciesProposal-alternative-\(index)")
                }
            }
            manualOption()
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
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(badge).font(.callout).foregroundStyle(Color("TextSecondary"))
                    if let scientific = value.scientificName {
                        Text(scientific).font(.title3.weight(.semibold))
                    }
                    if let common = value.commonName, common != value.scientificName {
                        Text(common).font(.body)
                    }
                    if isSelected {
                        Text("confirmSpecies.selected")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("Surface"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color("PrimaryAction"), in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color("PrimaryAction"))
                        .accessibilityHidden(true)
                }
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
