import SwiftUI

struct PlantPhotoPagerView: View {
    @ObservedObject var viewModel: PlantPhotoPagerViewModel
    let plantID: UUID
    var analyze: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            Color("SurfaceMuted").aspectRatio(4 / 3, contentMode: .fit).overlay {
                GeometryReader { geometry in
                    TabView(selection: Binding(get: { viewModel.selected }, set: viewModel.select)) {
                        ForEach(viewModel.isComplete ? viewModel.descriptors : [viewModel.current]) { descriptor in
                            page(descriptor, size: geometry.size).tag(descriptor.id)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }.clipped().clipShape(RoundedRectangle(cornerRadius: 22))
            Text(dateText).font(.subheadline).foregroundStyle(Color("TextSecondary"))
                .accessibilityIdentifier("plantPhotoDate-\(plantID)")
            if viewModel.isComplete, viewModel.descriptors.count > 1 {
                HStack {
                    Button { withAnimation(.easeInOut(duration: 0.25)) { viewModel.previous() } } label: { Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("plantPhotos.previous").accessibilityIdentifier("plantPhotoPrevious-\(plantID)").disabled(!viewModel.canPrevious)
                    Spacer()
                    Text("\(viewModel.index + 1) / \(viewModel.descriptors.count)").font(.caption)
                    Spacer()
                    Button { withAnimation(.easeInOut(duration: 0.25)) { viewModel.next() } } label: { Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("plantPhotos.next").accessibilityIdentifier("plantPhotoNext-\(plantID)").disabled(!viewModel.canNext)
                }
            }
            if let analyze {
                Button(action: analyze) { Label("analysis.open", systemImage: "sparkles").frame(maxWidth: .infinity, minHeight: 44) }
                    .buttonStyle(.bordered).buttonBorderShape(.capsule).accessibilityIdentifier("detailAnalyzePhoto-\(plantID)")
            }
            switch viewModel.metadataState {
            case .idle, .loading: ProgressView("plantPhotos.loadingMetadata")
            case .failed:
                Text("plantPhotos.metadataError").accessibilityIdentifier("plantPhotoMetadataError-\(plantID)")
                Button { viewModel.refresh() } label: { Text("plantPhotos.retryMetadata").frame(minWidth: 44, minHeight: 44) }
                    .accessibilityIdentifier("plantPhotoMetadataRetry-\(plantID)")
            case .loaded: EmptyView()
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("plantPhotoPager-\(plantID)")
    }

    private var dateText: String {
        let date = PlantDetailViewModel.formattedDate(viewModel.current.date, timeZone: viewModel.displayZone)
        return viewModel.selected == .initial(plantID) ? String(localized: "plantPhotos.initial") + " · " + date : date
    }
    private func page(_ descriptor: PlantPhotoDescriptor, size: CGSize) -> some View {
        let state = viewModel.imageState(for: descriptor.id)
        let isInitial = descriptor.id == .initial(plantID)
        return ZStack {
            Color("SurfaceMuted")
            switch state {
            case .loaded(let image):
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: size.width, height: size.height).clipped()
                    .contentShape(Rectangle())
            case .idle, .loading:
                ProgressView().accessibilityIdentifier("plantPhotoLoading-\(descriptor.id.stableKey)")
            case .failed:
                VStack {
                    Text("plantPhotos.imageError").accessibilityIdentifier(isInitial ? "detailPhotoError-\(plantID)" : "plantPhotoError-\(descriptor.id.stableKey)")
                    Button { viewModel.retryImage() } label: {
                        Text("plantPhotos.retryImage").frame(minWidth: 44, minHeight: 44)
                    }.accessibilityIdentifier(isInitial ? "retryDetailPhoto-\(plantID)" : "plantPhotoRetry-\(descriptor.id.stableKey)")
                }
            }
        }
        .frame(width: size.width, height: size.height).clipped()
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isInitial ? Text("detail.photo.initial") : Text("plantPhotos.add"))
        .accessibilityValue(imageValue(state, isInitial: isInitial))
        .accessibilityIdentifier(isInitial ? "detailPhoto-\(plantID)" : "plantPhotoImage-\(descriptor.id.stableKey)")
        .accessibilityHidden(descriptor.id != viewModel.selected)
    }

    private func imageValue(_ state: PlantPhotoPagerViewModel.ImageState, isInitial: Bool) -> Text {
        switch state {
        case .loaded(let image):
            if isInitial { return Text("collection.photo.loaded") }
            return Text(verbatim: String(localized: "collection.photo.loaded") + " · \(Int(image.size.width)) × \(Int(image.size.height))")
        case .failed: return Text("detail.photo.error")
        default: return Text("detail.photo.loading")
        }
    }
}
