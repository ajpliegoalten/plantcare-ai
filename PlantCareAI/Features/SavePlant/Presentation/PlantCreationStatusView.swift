import SwiftUI

struct PlantCreationStatusView: View {
    @ObservedObject var viewModel: IdentificationPhotoViewModel

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.creationState == .failed || viewModel.careState == .failed || viewModel.careState == .cancelled {
                if let name = viewModel.confirmedIdentity?.manualName {
                    Text(verbatim: name).accessibilityIdentifier("confirmedManualName")
                } else if let name = viewModel.confirmedIdentity?.scientificName ?? viewModel.confirmedIdentity?.commonName {
                    Text(verbatim: name).accessibilityIdentifier("confirmedScientificName")
                }
            }
            if viewModel.creationState == .validating || viewModel.isSaving {
                ProgressView("savePlant.loading").accessibilityIdentifier("plantCreationLoading")
                if !viewModel.isSaving {
                    Button("identifyCandidates.cancelRequest") { viewModel.cancelCreation() }.frame(minHeight: 44)
                }
            } else if viewModel.creationState == .failed {
                Text("savePlant.error").accessibilityIdentifier("plantCreationError")
                Button { viewModel.retrySave() } label: {
                    Text("savePlant.retry").foregroundStyle(Color("Surface")).frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).accessibilityIdentifier("retryPlantCreation")
                changeSpecies
            } else if viewModel.creationState != .saved {
                if viewModel.isGeneratingCare {
                    ProgressView("careSheet.loading").accessibilityIdentifier("careSheetLoading")
                    Button("identifyCandidates.cancelRequest") { viewModel.cancelCare() }
                        .frame(minHeight: 44).accessibilityIdentifier("cancelCareSheetRequest")
                    changeSpecies.disabled(true)
                } else {
                    if viewModel.careState == .failed || viewModel.careState == .cancelled {
                        Text(message).accessibilityIdentifier("careSheetError")
                    }
                    Button { viewModel.retryCare() } label: {
                        Text("careSheet.retry").foregroundStyle(Color("Surface")).frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).accessibilityIdentifier("retryCareSheet")
                    changeSpecies
                }
            }
        }
    }

    private var changeSpecies: some View {
        VStack(spacing: 12) {
            Button("confirmSpecies.change") { viewModel.changeConfirmedSpecies() }
                .frame(minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("changeConfirmedSpecies")
            if viewModel.canReturnToAIProposals {
                Button("manualSpecies.returnToAI") { viewModel.returnToAIProposals() }
                    .frame(minHeight: 44).buttonStyle(.bordered).accessibilityIdentifier("returnToAIProposals")
            }
        }
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
