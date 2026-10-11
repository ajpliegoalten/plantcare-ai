import SwiftUI

struct ConfirmedSpeciesView: View {
    let identity: ConfirmedDraftIdentity
    let canChange: Bool
    let change: () -> Void
    var canReturnToAI = false
    var returnToAI: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("confirmSpecies.confirmed", systemImage: "checkmark.circle")
                .font(.headline).accessibilityIdentifier("confirmedSpeciesHeading")
            if let name = identity.manualName {
                Text(name).font(.title3.weight(.semibold)).accessibilityIdentifier("confirmedManualName")
                Text("manualSpecies.confirmedProvenance").accessibilityIdentifier("manualSpeciesProvenance")
            }
            if let scientific = identity.scientificName {
                Text(scientific).font(.title3.weight(.semibold)).accessibilityIdentifier("confirmedScientificName")
            }
            if let common = identity.commonName, common != identity.scientificName {
                Text(common).accessibilityIdentifier("confirmedCommonName")
            }
            Text("confirmSpecies.caution")
            Text("confirmSpecies.draft").accessibilityIdentifier("confirmedDraftNotice")
            Text("confirmSpecies.futureCare").font(.callout)
            Button("confirmSpecies.change", action: change)
                .frame(minHeight: 44).buttonStyle(.bordered).disabled(!canChange)
                .accessibilityIdentifier("changeConfirmedSpecies")
            if canReturnToAI {
                Button("manualSpecies.returnToAI", action: returnToAI)
                    .frame(minHeight: 44).buttonStyle(.bordered)
                    .accessibilityIdentifier("returnToAIProposals")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color("TextPrimary")).multilineTextAlignment(.leading)
        .padding(16).background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
    }
}
