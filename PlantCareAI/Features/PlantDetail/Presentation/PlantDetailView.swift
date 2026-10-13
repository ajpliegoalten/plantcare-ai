import SwiftUI

struct PlantDetailView: View {
    @StateObject private var viewModel: PlantDetailViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var editor: EditPlantViewModel?
    @State private var careEditor: RegisterCareViewModel?
    @State private var photoEditor: AddPlantPhotoViewModel?
    @State private var analysisEditor: PlantPhotoAnalysisViewModel?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let isCoveredByHistory: () -> Bool

    init(viewModel: PlantDetailViewModel, isCoveredByHistory: @escaping () -> Bool = { false }) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.isCoveredByHistory = isCoveredByHistory
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch viewModel.state {
                case .loading:
                    ProgressView().frame(maxWidth: .infinity)
                case .notFound:
                    Text("detail.notFound").accessibilityIdentifier("detailNotFound")
                case .failed:
                    Text("detail.storageError").accessibilityIdentifier("detailStorageError")
                case .loaded(let plant):
                    if let pager = viewModel.photoPager {
                        PlantPhotoPagerView(viewModel: pager, plantID: plant.id,
                            analyze: viewModel.makeAnalysis == nil ? nil : { analysisEditor = viewModel.analysisEditor() })
                    } else { photo }
                    identity(plant)
                    if viewModel.makeAddPhoto != nil {
                        Button { photoEditor = viewModel.photoEditor() } label: {
                            Label("plantPhotos.add", systemImage: "photo.badge.plus").frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(Color("Surface"))
                        }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).tint(Color("PrimaryAction"))
                            .accessibilityIdentifier("detailAddPhoto-\(plant.id)")
                        if viewModel.photoConfirmation != nil {
                            Label("plantPhotos.confirmed", systemImage: "checkmark.circle.fill")
                                .accessibilityIdentifier("additionalPhotoConfirmation-\(plant.id)")
                        }
                    }
                    careRegistration
                    history(plant)
                    careSheet(plant.careSheet)
                }
            }
            .font(.body)
            .foregroundStyle(Color("TextPrimary"))
            .fixedSize(horizontal: false, vertical: true)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color("Background").ignoresSafeArea())
        .navigationTitle(Text("detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .loaded = viewModel.state {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editor = viewModel.editor() } label: { Text("edit.open").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityIdentifier("editPlant-\(viewModel.id)")
                }
            }
        }
        .sheet(item: $editor) { EditPlantView(viewModel: $0) }
        .sheet(item: $careEditor) { RegisterCareView(viewModel: $0) }
        .sheet(item: $photoEditor) { AddPlantPhotoView(viewModel: $0, headerPhoto: viewModel.formPhoto, onFinished: { photoEditor = nil }) }
        .sheet(item: $analysisEditor, onDismiss: { analysisEditor?.close() }) { PlantPhotoAnalysisView(viewModel: $0) }
        .onChange(of: viewModel.photoConfirmation) { _, confirmed in
            if confirmed != nil { photoEditor = nil }
        }
        .accessibilityIdentifier("plantDetail-\(viewModel.id)")
        .task { await viewModel.load() }
        .onDisappear {
            // A presented sheet (or its camera cover) is not navigation away
            // from this plant: keep its session and confirmed page alive.
            if photoEditor == nil && editor == nil && careEditor == nil && analysisEditor == nil {
                viewModel.cancelLoading(preservingPhotoSelection: isCoveredByHistory())
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active {
            viewModel.lastWatering.foreground(); viewModel.photoPager?.refreshDisplayZone()
        } }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in viewModel.photoPager?.refreshDisplayZone() }
    }

    private func history(_ plant: Plant) -> some View {
        NavigationLink(value: PlantTimelineRoute(plantID: plant.id)) {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color("Primary"))
                    .frame(width: 44, height: 44)
                    .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("timeline.open").font(.headline)
                    Text("timeline.subtitle").font(.subheadline).foregroundStyle(Color("TextSecondary"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").foregroundStyle(Color("TextSecondary")).accessibilityHidden(true)
            }
            .padding(16).frame(maxWidth: .infinity, minHeight: 44)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("detailHistory-\(plant.id)")
    }

    private func identity(_ plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.name).font(.title2.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("selectedPlant-\(plant.id)")
                    Text(plant.confirmedSpecies).font(.subheadline).italic().foregroundStyle(Color("TextSecondary"))
                        .accessibilityIdentifier("detailSpecies-\(plant.id)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "leaf.fill")
                    .font(.title3)
                    .foregroundStyle(Color("Primary"))
                    .frame(width: 40, height: 40)
                    .background(Color("SurfaceMuted"), in: Circle())
                    .accessibilityHidden(true)
            }
            if let location = PlantDetailViewModel.visibleLocation(plant.location) {
                HStack(alignment: .top) {
                    Image(systemName: "mappin.and.ellipse").accessibilityHidden(true)
                    Text(location)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("detailLocation-\(plant.id)")
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "calendar").accessibilityHidden(true)
                Text("detail.createdAt \(PlantDetailViewModel.formattedDate(plant.createdAt))")
                    .accessibilityIdentifier("detailCreatedAt-\(plant.id)")
            }
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 12))
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color("Primary").opacity(0.04), radius: 10, y: 3)
    }

    private var careRegistration: some View {
        PlantCareRegistration(viewModel: viewModel) { careEditor = viewModel.careEditor() }
    }

    private struct PlantCareRegistration: View {
        @ObservedObject var viewModel: PlantDetailViewModel
        @ObservedObject var lastWatering: LastWateringHintViewModel
        let onOpen: () -> Void

        init(viewModel: PlantDetailViewModel, onOpen: @escaping () -> Void) {
            self.viewModel = viewModel
            self.lastWatering = viewModel.lastWatering
            self.onOpen = onOpen
        }

        var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label("detail.care.registrationTitle", systemImage: "leaf.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("CareTerracotta"))
            }
            if viewModel.careConfirmation != nil {
                Label("care.confirmed", systemImage: "checkmark.circle.fill")
                    .accessibilityIdentifier("careConfirmation")
            }
            if case .loaded = lastWatering.state {
                LastWateringHintView(viewModel: lastWatering, style: .detailRow)
            }
            Button(action: onOpen) {
                Label("detail.care.register", systemImage: "leaf.fill")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Color("Primary"))
                    .background(Color("CareMint"), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("detailRegisterCare-\(viewModel.id)")
            Text("detail.watering.checkSubstrate")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color("Primary").opacity(0.04), radius: 10, y: 3)
        }
    }

    private func careSheet(_ sheet: CareSheet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("detail.care.title", systemImage: "sparkles")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("detail.care.subtitle")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))
            }
            // Eager Grid keeps every saved field available to accessibility,
            // including long text; equal columns and row heights on normal text.
            Grid(alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8) {
                if dynamicTypeSize.isAccessibilitySize {
                    careCard("light", "sun.max.fill", sheet.light, tint: "CareOchre", background: "CareHoney")
                    careCard("watering", "drop.fill", sheet.watering, tint: "Primary", background: "CareMint")
                    careCard("humidity", "humidity", sheet.humidity, tint: "Primary", background: "SurfaceMuted")
                    careCard("temperature", "thermometer.medium", sheet.temperature, tint: "CareTerracotta", background: "CarePeach")
                    careCard("substrate", "leaf.fill", sheet.substrate, tint: "Primary", background: "SurfaceMuted")
                    careCard("fertilizer", "flask.fill", sheet.fertilizer, tint: "CareOchre", background: "CareHoney")
                } else {
                    GridRow {
                        careCard("light", "sun.max.fill", sheet.light, tint: "CareOchre", background: "CareHoney")
                        careCard("watering", "drop.fill", sheet.watering, tint: "Primary", background: "CareMint")
                    }
                    GridRow {
                        careCard("humidity", "humidity", sheet.humidity, tint: "Primary", background: "SurfaceMuted")
                        careCard("temperature", "thermometer.medium", sheet.temperature, tint: "CareTerracotta", background: "CarePeach")
                    }
                    GridRow {
                        careCard("substrate", "leaf.fill", sheet.substrate, tint: "Primary", background: "SurfaceMuted")
                        careCard("fertilizer", "flask.fill", sheet.fertilizer, tint: "CareOchre", background: "CareHoney")
                    }
                }
            }
            Text("detail.care.disclaimer")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .accessibilityIdentifier("detailDisclaimer")
        }
    }

    private func careCard(_ field: String, _ symbol: String, _ value: String, tint: String, background: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 6) {
                Text(LocalizedStringKey("detail.care." + field)).font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: symbol)
                    .font(.body)
                    .foregroundStyle(Color(tint))
                    .frame(width: 32, height: 32)
                    .background(Color(background), in: Circle())
                    .accessibilityHidden(true)
            }
            Text(value).font(.subheadline).foregroundStyle(Color("TextSecondary"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color("Primary").opacity(0.04), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("detailCare-\(field)-\(viewModel.id)")
    }

    private var photo: some View {
        VStack(spacing: 16) {
            Color("SurfaceMuted")
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    GeometryReader { geometry in
                        Group {
                            switch viewModel.photoState {
                            case .loaded(let image):
                                Image(uiImage: image).resizable().scaledToFill()
                            case .idle, .loading:
                                ProgressView().accessibilityLabel(Text("detail.photo.loading"))
                            case .failed:
                                Image(systemName: "photo.badge.exclamationmark").font(.largeTitle).accessibilityHidden(true)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                    }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("detail.photo.initial"))
                .accessibilityValue(Text(photoAccessibilityValue))
                .accessibilityIdentifier("detailPhoto-\(viewModel.id)")
            if case .failed = viewModel.photoState {
                VStack(alignment: .leading, spacing: 12) {
                    Text("detail.photo.error").font(.body.weight(.semibold))
                        .accessibilityIdentifier("detailPhotoError-\(viewModel.id)")
                    Text("detail.photo.explanation").foregroundStyle(Color("TextSecondary"))
                    Button { Task { await viewModel.retryPhoto() } } label: {
                        Text("detail.photo.retry").font(.body.weight(.semibold)).frame(minWidth: 44, minHeight: 44)
                    }
                    .foregroundStyle(Color("PrimaryAction"))
                    .accessibilityIdentifier("retryDetailPhoto-\(viewModel.id)")
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 22))
            }
        }
    }

    private var photoAccessibilityValue: LocalizedStringKey {
        switch viewModel.photoState {
        case .idle, .loading: return "detail.photo.loading"
        case .loaded: return "collection.photo.loaded"
        case .failed: return "detail.photo.error"
        }
    }
}
