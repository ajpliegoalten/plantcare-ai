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
                    Text("identificationPhoto.future").font(.footnote)
                        .accessibilityIdentifier("identificationUnavailable")
                    if viewModel.authorizationState == .unavailable {
                        Text("externalAIConsent.unavailable").accessibilityIdentifier("externalAIUnavailable")
                    }
                    if viewModel.authorizationState == .failed {
                        Text("externalAIConsent.error").accessibilityIdentifier("externalAIConsentError")
                    }
                    if viewModel.authorizationState == .checkingAuthorization || viewModel.authorizationState == .continuing {
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
            ExternalAIConsentView(accept: { viewModel.confirmAuthorization() }, cancel: { viewModel.cancelAuthorization() })
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
}
