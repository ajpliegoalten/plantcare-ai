import SwiftUI

struct PlantDetailView: View {
    @StateObject private var viewModel: PlantDetailViewModel

    init(viewModel: PlantDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                    photo
                    identity(plant)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("detail.care.title").font(.title2.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        Text("detail.care.subtitle").foregroundStyle(Color("TextSecondary"))
                        VStack(alignment: .leading, spacing: 16) {
                            careRow("light", "sun.max", plant.careSheet.light)
                            separator
                            careRow("watering", "drop", plant.careSheet.watering)
                            separator
                            careRow("humidity", "humidity", plant.careSheet.humidity)
                            separator
                            careRow("temperature", "thermometer", plant.careSheet.temperature)
                            separator
                            careRow("substrate", "leaf", plant.careSheet.substrate)
                            separator
                            careRow("fertilizer", "leaf.circle", plant.careSheet.fertilizer)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
                        Text("detail.care.disclaimer").foregroundStyle(Color("TextSecondary"))
                            .accessibilityIdentifier("detailDisclaimer")
                    }
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
        .accessibilityIdentifier("plantDetail-\(viewModel.id)")
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancelLoading() }
    }

    private var separator: some View { Color("Outline").frame(height: 0.5).accessibilityHidden(true) }

    private func identity(_ plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(plant.name).font(.title2.weight(.semibold)).accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("selectedPlant-\(plant.id)")
            Text(plant.confirmedSpecies).italic().foregroundStyle(Color("TextSecondary"))
                .accessibilityIdentifier("detailSpecies-\(plant.id)")
            if let location = PlantDetailViewModel.visibleLocation(plant.location) {
                HStack(alignment: .top) {
                    Image(systemName: "mappin.and.ellipse").accessibilityHidden(true)
                    Text(location)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("detailLocation-\(plant.id)")
            }
            Text("detail.createdAt \(PlantDetailViewModel.formattedDate(plant.createdAt))")
                .foregroundStyle(Color("TextSecondary"))
                .accessibilityIdentifier("detailCreatedAt-\(plant.id)")
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
    }

    private func careRow(_ field: String, _ symbol: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: symbol).foregroundStyle(Color("Primary")).accessibilityHidden(true)
                Text(LocalizedStringKey("detail.care." + field)).font(.body.weight(.semibold))
            }
            Text(value)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
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
