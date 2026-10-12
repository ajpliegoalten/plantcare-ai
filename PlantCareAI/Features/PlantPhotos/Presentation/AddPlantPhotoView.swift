import SwiftUI
import PhotosUI

struct AddPlantPhotoView: View {
    @StateObject var viewModel: AddPlantPhotoViewModel
    var headerPhoto: UIImage? = nil
    var onFinished: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var selection: PhotosPickerItem?
    @State private var pendingCapture: Data?

    var body: some View {
        let sourcesEnabled = !viewModel.isBusy
        return NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PlantFormHeader(name: viewModel.plant.name, subtitle: String(localized: "plantPhotos.belongs"),
                        photo: headerPhoto, photoSize: 56)
                    PhotoSelectionPreview(image: viewModel.preview, previewID: "additionalPhotoPreview",
                        placeholderID: "additionalPhotoPlaceholder",
                        value: "\(viewModel.photo?.width ?? 0) × \(viewModel.photo?.height ?? 0)", previewLabel: "plantPhotos.preview")
                    DatePicker("plantPhotos.date", selection: Binding(get: { viewModel.occurredAt }, set: viewModel.selectDate),
                               in: ...viewModel.latestSelectableDate, displayedComponents: .date)
                        .environment(\.calendar, viewModel.calendar).environment(\.timeZone, viewModel.displayZone)
                        .disabled(viewModel.isBusy).accessibilityIdentifier("additionalPhotoDate")
                    if viewModel.isLoading { ProgressView("identificationPhoto.loading").accessibilityIdentifier("additionalPhotoLoading") }
                    if viewModel.preparationError != nil { Text("identificationPhoto.error").accessibilityIdentifier("additionalPhotoError") }
                    if let issue = viewModel.cameraIssue {
                        Text(cameraMessage(issue))
                        if issue == .denied {
                            Button("identificationPhoto.settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                            }.frame(minHeight: 44)
                        }
                    }
                    PhotoActionsSurface {
                        PhotosPicker(selection: $selection, matching: .images, preferredItemEncoding: .current) {
                            PhotoActionLabel(title: "identificationPhoto.gallery", symbol: "photo", prominent: true, enabled: sourcesEnabled)
                        }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                            .disabled(viewModel.isBusy).accessibilityIdentifier("additionalPhotoGallery")
                        Button { viewModel.requestCamera() } label: {
                            PhotoActionLabel(title: "identificationPhoto.camera", symbol: "camera", enabled: sourcesEnabled)
                        }.buttonStyle(.bordered).buttonBorderShape(.capsule)
                            .disabled(viewModel.isBusy).accessibilityIdentifier("additionalPhotoCamera")
                    if case .error = viewModel.state {
                        Text("plantPhotos.saveError").accessibilityIdentifier("additionalPhotoError")
                    }
                    if viewModel.state == .saving || viewModel.state == .validating {
                        ProgressView("plantPhotos.saving").accessibilityIdentifier("additionalPhotoSaving")
                    }
                    Button { Task { await viewModel.save() } } label: {
                        Text(viewModel.state.isPhotoError ? "plantPhotos.retrySave" : "plantPhotos.save")
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(viewModel.canSave ? Color("Surface") : Color("TextSecondary"))
                    }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                        .disabled(!viewModel.canSave)
                        .accessibilityIdentifier(viewModel.state.isPhotoError ? "retryAdditionalPhoto" : "saveAdditionalPhoto")
                    }
                    #if DEBUG && targetEnvironment(simulator)
                    ForEach(viewModel.testSelections.keys.sorted(), id: \.self) { name in
                        Button("Test \(name)") {
                            let bytes = viewModel.testSelections[name]
                            viewModel.select {
                                if ProcessInfo.processInfo.arguments.contains("--additional-photo-delay") { try await Task.sleep(for: .seconds(2)) }
                                return bytes
                            }
                        }.frame(minHeight: 44).disabled(viewModel.isBusy).accessibilityIdentifier("fixture-additional-\(name)")
                    }
                    #endif
                }.padding(20)
            }.background(Color("Surface")).foregroundStyle(Color("TextPrimary"))
                .navigationTitle("plantPhotos.add").navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color("Surface"), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button("identificationPhoto.cancel") { viewModel.close(); finish() }
                        .disabled(!viewModel.canClose).accessibilityIdentifier("cancelAdditionalPhoto")
                } }
        }.tint(Color("PrimaryAction")).accessibilityIdentifier("addPlantPhotoForm")
            .presentationDetents([.fraction(0.95)]).presentationCornerRadius(24)
            .presentationDragIndicator(.visible).interactiveDismissDisabled(!viewModel.canClose)
            .onChange(of: viewModel.state) { _, state in
                if state == .saved { finish() }
            }
            .onChange(of: selection) { _, item in
                guard let item else { return }
                viewModel.select { try await item.loadTransferable(type: Data.self) }; selection = nil
            }
            .fullScreenCover(isPresented: $viewModel.presentsCamera, onDismiss: {
                if let data = pendingCapture { pendingCapture = nil; viewModel.select { data } }
            }) {
                CameraPickerView { data in pendingCapture = data; viewModel.presentsCamera = false }.ignoresSafeArea()
            }
            .onDisappear { if !viewModel.presentsCamera { viewModel.close() } }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in viewModel.refreshDisplayZone() }
    }

    private func cameraMessage(_ result: CameraAccessResult) -> LocalizedStringKey {
        switch result {
        case .denied: return "identificationPhoto.cameraDenied"
        case .restricted: return "identificationPhoto.cameraRestricted"
        default: return "identificationPhoto.cameraUnavailable"
        }
    }
    private func finish() { if let onFinished { onFinished() } else { dismiss() } }
}

private extension AddPlantPhotoViewModel.State {
    var isPhotoError: Bool { if case .error = self { return true }; return false }
}
