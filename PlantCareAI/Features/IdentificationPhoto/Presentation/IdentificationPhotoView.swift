import SwiftUI
import PhotosUI

struct IdentificationPhotoView: View {
    @StateObject var viewModel: IdentificationPhotoViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var selection: PhotosPickerItem?
    @State private var pendingCapture: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    preview
                    if let identity = viewModel.confirmedIdentity {
                        ConfirmedSpeciesView(identity: identity, canChange: !viewModel.isBusy && !viewModel.presentsCamera,
                                             change: { viewModel.changeConfirmedSpecies() })
                    } else if let result = viewModel.identificationResult, let revision = viewModel.resultID {
                        IdentificationResultView(result: result, selected: viewModel.selectedProposal,
                            canSelect: viewModel.canSelectProposal, canConfirm: viewModel.canConfirmSpecies,
                            select: { viewModel.selectProposal($0, resultID: revision) },
                            confirm: { viewModel.confirmSpecies(resultID: revision) })
                    }
                    if viewModel.hasConfirmationError {
                        Text("confirmSpecies.error").accessibilityIdentifier("speciesConfirmationError")
                    }
                    if viewModel.authorizationState == .continuing {
                        ProgressView("identifyCandidates.loading").accessibilityIdentifier("identificationLoading")
                        Button("identifyCandidates.cancelRequest") { viewModel.cancelAuthorization() }
                            .frame(minHeight: 44).accessibilityIdentifier("cancelIdentificationRequest")
                    }
                    if let error = viewModel.identificationError {
                        Text(identificationMessage(error)).accessibilityIdentifier("identificationError")
                    }
                    if viewModel.isLoading {
                        ProgressView("identificationPhoto.loading")
                            .accessibilityIdentifier("photoLoading")
                    }
                    if viewModel.isCheckingCamera { ProgressView("identificationPhoto.cameraChecking") }
                    if let error = viewModel.error {
                        Text(error == .tooLarge ? "identificationPhoto.tooLarge" : "identificationPhoto.error")
                            .accessibilityIdentifier("photoError")
                    }
                    if let issue = viewModel.cameraIssue {
                        Text(cameraMessage(issue)).accessibilityIdentifier("cameraIssue")
                        if issue == .denied {
                            Button("identificationPhoto.settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                            }.frame(minHeight: 44)
                        }
                    }
                    PhotosPicker(selection: $selection, matching: .images, preferredItemEncoding: .current) {
                        Label("identificationPhoto.gallery", systemImage: "photo")
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(viewModel.isBusy ? Color("TextSecondary") : Color("Surface"))
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("chooseGalleryPhoto")
                    .disabled(viewModel.isBusy)
                    Button { viewModel.takePhoto() } label: {
                        Label("identificationPhoto.camera", systemImage: "camera")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("takePlantPhoto")
                    .disabled(viewModel.isBusy)
                    Button { viewModel.identifyPhoto() } label: {
                        Text("identificationPhoto.identify").frame(minHeight: 44)
                            .foregroundStyle(viewModel.canIdentify ? Color("Surface") : Color("TextSecondary"))
                    }
                        .buttonStyle(.borderedProminent).disabled(!viewModel.canIdentify)
                        .accessibilityIdentifier("identifyPhoto")
                    Text("identifyCandidates.explanation").font(.footnote)
                        .accessibilityIdentifier("identificationUnavailable")
                    if viewModel.authorizationState == .unavailable {
                        Text(viewModel.usesRealRecipient ? "identifyCandidates.configurationUnavailable" : "externalAIConsent.unavailable").accessibilityIdentifier("externalAIUnavailable")
                    }
                    if viewModel.authorizationState == .failed && viewModel.identificationError == nil {
                        Text("externalAIConsent.error").accessibilityIdentifier("externalAIConsentError")
                    }
                    if viewModel.authorizationState == .checkingAuthorization {
                        ProgressView("externalAIConsent.checking")
                    }
                    #if DEBUG && targetEnvironment(simulator)
                    if viewModel.testInvocationCount != nil {
                        Text("Instrumented invocations: \(viewModel.invocationCount)")
                            .accessibilityIdentifier("externalAIInvocationCount")
                    }
                    if !viewModel.testSelections.isEmpty {
                        ForEach(viewModel.testSelections.keys.sorted(), id: \.self) { name in
                            Button("Test \(name)") {
                                let bytes = viewModel.testSelections[name]
                                viewModel.select {
                                    try await Task.sleep(for: .seconds(2))
                                    return bytes
                                }
                            }.frame(minHeight: 44).disabled(viewModel.isBusy)
                                .accessibilityIdentifier("fixture-photo-\(name)")
                        }
                    }
                    #endif
                }
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(20)
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle("identificationPhoto.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("identificationPhoto.cancel") { viewModel.close(); dismiss() }
                        .accessibilityIdentifier("cancelIdentificationPhoto")
                }
            }
        }
        .tint(Color("PrimaryAction"))
        .sheet(isPresented: Binding(get: { viewModel.authorizationState == .awaitingConfirmation }, set: { showing in
            if !showing, viewModel.authorizationState == .awaitingConfirmation { viewModel.cancelAuthorization() }
        })) {
            ExternalAIConsentView(usesRealRecipient: viewModel.usesRealRecipient, destination: viewModel.destinationNotice, accept: { viewModel.confirmAuthorization() }, cancel: { viewModel.cancelAuthorization() })
        }
        .onChange(of: selection) { _, item in
            guard let item else { return }
            viewModel.select { try await item.loadTransferable(type: Data.self) }
            selection = nil // Selecting the same asset again remains possible.
        }
        .fullScreenCover(isPresented: $viewModel.presentsCamera, onDismiss: {
            if let data = pendingCapture {
                pendingCapture = nil
                viewModel.select { data }
            }
        }) {
            CameraPickerView { data in
                pendingCapture = data
                viewModel.presentsCamera = false
            }.ignoresSafeArea()
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).fill(Color("Surface"))
            if let photo = viewModel.photo, let image = UIImage(data: photo.jpeg) {
                Image(uiImage: image).resizable().scaledToFit()
                    .accessibilityLabel(Text("identificationPhoto.preview"))
                    .accessibilityIdentifier("identificationPhotoPreview")
                    .accessibilityValue("\(photo.width) × \(photo.height)")
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "leaf").font(.largeTitle).accessibilityHidden(true)
                    Text("identificationPhoto.placeholder")
                }.padding(20).accessibilityIdentifier("identificationPhotoPlaceholder")
            }
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func cameraMessage(_ issue: CameraAccessResult) -> LocalizedStringKey {
        switch issue {
        case .unavailable: return "identificationPhoto.cameraUnavailable"
        case .denied: return "identificationPhoto.cameraDenied"
        case .restricted: return "identificationPhoto.cameraRestricted"
        case .authorized: return "identificationPhoto.cameraUnavailable"
        }
    }

    private func identificationMessage(_ error: SpeciesIdentificationError) -> LocalizedStringKey {
        switch error {
        case .configuration: return "identifyCandidates.configurationUnavailable"
        case .network: return "identifyCandidates.networkError"
        case .timeout: return "identifyCandidates.timeoutError"
        case .unauthorized: return "identifyCandidates.authorizationError"
        case .rateLimited: return "identifyCandidates.rateLimitError"
        case .service: return "identifyCandidates.serviceError"
        case .rejected, .invalidResponse: return "identifyCandidates.responseError"
        }
    }
}
