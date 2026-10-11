import SwiftUI

struct CareSheetReviewView: View {
    @ObservedObject var viewModel: IdentificationPhotoViewModel
    let identity: ConfirmedDraftIdentity

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let name = identity.manualName {
                Text(verbatim: name).font(.title3.weight(.semibold)).accessibilityIdentifier("confirmedManualName")
                Text("manualSpecies.confirmedProvenance").accessibilityIdentifier("manualSpeciesProvenance")
            } else {
                if let scientific = identity.scientificName {
                    Text(verbatim: scientific).font(.title3.weight(.semibold)).accessibilityIdentifier("confirmedScientificName")
                }
                if let common = identity.commonName, common != identity.scientificName {
                    Text(verbatim: common).accessibilityIdentifier("confirmedCommonName")
                }
                Text("careSheet.aiIdentity")
            }
            if viewModel.isGeneratingCare {
                ProgressView("careSheet.loading").accessibilityIdentifier("careSheetLoading")
                Button("identifyCandidates.cancelRequest") { viewModel.cancelCare() }
                    .frame(minHeight: 44).accessibilityIdentifier("cancelCareSheetRequest")
            }
            if let sheet = viewModel.reviewableCareSheet {
                Text("careSheet.orientation").font(.callout).accessibilityIdentifier("careSheetOrientation")
                field("Luz", sheet.light, "light")
                field("Riego", sheet.watering, "watering")
                field("Humedad", sheet.humidity, "humidity")
                field("Temperatura", sheet.temperature, "temperature")
                field("Sustrato", sheet.substrate, "substrate")
                field("Abonado", sheet.fertilizer, "fertilizer")
            }
            if viewModel.careState == .failed || viewModel.careState == .cancelled {
                Text(message).accessibilityIdentifier("careSheetError")
                Button { viewModel.retryCare() } label: {
                    Text("careSheet.retry").foregroundStyle(Color("Surface")).frame(minHeight: 44)
                }.buttonStyle(.borderedProminent).accessibilityIdentifier("retryCareSheet")
            }
            Button("confirmSpecies.change") { viewModel.changeConfirmedSpecies() }
                .frame(minHeight: 44).buttonStyle(.bordered).disabled(viewModel.isBusy)
                .accessibilityIdentifier("changeConfirmedSpecies")
            if viewModel.canReturnToAIProposals {
                Button("manualSpecies.returnToAI") { viewModel.returnToAIProposals() }
                    .frame(minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("returnToAIProposals")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color("TextPrimary")).multilineTextAlignment(.leading)
        .padding(16).background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
    }

    private func field(_ title: String, _ text: String, _ id: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            Text(verbatim: text).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("careSheet-" + id)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var message: LocalizedStringKey {
        if viewModel.careState == .cancelled { return "careSheet.cancelled" }
        switch viewModel.careError {
        case .configuration: return "careSheet.configuration"
        case .invalidInput: return "careSheet.invalidInput"
        case .network: return "careSheet.network"
        case .timeout: return "careSheet.timeout"
        case .unauthorized: return "careSheet.unauthorized"
        case .rateLimited: return "careSheet.rateLimited"
        case .service: return "careSheet.service"
        case .rejected: return "careSheet.rejected"
        case .invalidResponse, .none: return "careSheet.invalidResponse"
        }
    }
}
