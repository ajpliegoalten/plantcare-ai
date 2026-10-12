import SwiftUI

struct PlantCardView: View {
    @ObservedObject var viewModel: PlantCardViewModel
    @ObservedObject private var lastWatering: LastWateringHintViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: PlantCardViewModel) {
        self.viewModel = viewModel
        self.lastWatering = viewModel.lastWatering
    }

    private var selectionLabel: String {
        ([viewModel.plant.name, viewModel.plant.confirmedSpecies] +
         [viewModel.plant.location].compactMap { $0 }).joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: viewModel.id) {
                VStack(alignment: .leading, spacing: 0) {
                    photo
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.plant.name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color("TextPrimary"))
                        Text(viewModel.plant.confirmedSpecies)
                            .font(.body)
                            .foregroundStyle(Color("TextSecondary"))
                        if case .loaded = lastWatering.state {
                            LastWateringHintView(viewModel: lastWatering, style: .compactCard)
                        }
                        if let location = viewModel.plant.location {
                            Text(location)
                                .font(.body)
                                .foregroundStyle(Color("TextSecondary"))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selectionLabel)
            .accessibilityValue(Text(accessibilityValue))
            .accessibilityHint(Text("collection.select.hint"))
            .accessibilityIdentifier("plantCard-\(viewModel.id)")

            if case .failed = viewModel.photoState {
                VStack(alignment: .leading, spacing: 8) {
                    Button { Task { await viewModel.retry() } } label: {
                        Text("collection.photo.retry")
                            .font(.body.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                    .foregroundStyle(Color("PrimaryAction"))
                    .accessibilityIdentifier("retryPlantPhoto-\(viewModel.id)")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color("Outline"), lineWidth: 0.5))
        .task { await viewModel.load() }
        .onAppear { lastWatering.appear() }
        .onDisappear { viewModel.cancelLoading(); lastWatering.disappear() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { lastWatering.foreground() } }
    }

    private var photo: some View {
        Color("SurfaceMuted")
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    switch viewModel.photoState {
                    case .loaded(let image):
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .accessibilityIdentifier("plantPhoto-\(viewModel.id)")
                    case .idle, .loading:
                        ProgressView().frame(width: geometry.size.width, height: geometry.size.height)
                    case .failed:
                        VStack(spacing: 12) {
                            Image(systemName: "photo").font(.largeTitle)
                            Text("collection.photo.error")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .accessibilityIdentifier("plantPhotoError-\(viewModel.id)")
                        }
                            .padding(16)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private var photoAccessibilityValue: LocalizedStringKey {
        switch viewModel.photoState {
        case .idle, .loading: return "collection.photo.loading"
        case .loaded: return "collection.photo.loaded"
        case .failed: return "collection.photo.error"
        }
    }

    private var accessibilityValue: String {
        let photo: String
        switch viewModel.photoState {
        case .idle, .loading: photo = String(localized: "collection.photo.loading")
        case .loaded: photo = String(localized: "collection.photo.loaded")
        case .failed: photo = String(localized: "collection.photo.error")
        }
        return [photo, lastWatering.value(compact: true)].compactMap { $0 }.joined(separator: ", ")
    }
}
