import SwiftUI

struct PlantPhotoPagerView: View {
    @ObservedObject var viewModel: PlantPhotoPagerViewModel
    let plantID: UUID

    var body: some View {
        VStack(spacing: 8) {
            Color("SurfaceMuted").aspectRatio(4 / 3, contentMode: .fit).overlay {
                GeometryReader { geometry in
                ZStack {
                switch viewModel.imageState {
                case .loaded(let image):
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                case .idle, .loading: ProgressView().accessibilityIdentifier("plantPhotoLoading-\(viewModel.selected.stableKey)")
                case .failed:
                    VStack {
                        Text("plantPhotos.imageError").accessibilityIdentifier(viewModel.selected == .initial(plantID) ? "detailPhotoError-\(plantID)" : "plantPhotoError-\(viewModel.selected.stableKey)")
                        Button { viewModel.retryImage() } label: {
                            Text("plantPhotos.retryImage").frame(minWidth: 44, minHeight: 44)
                        }
                            .accessibilityIdentifier(viewModel.selected == .initial(plantID) ? "retryDetailPhoto-\(plantID)" : "plantPhotoRetry-\(viewModel.selected.stableKey)")
                    }
                }
                }.frame(width: geometry.size.width, height: geometry.size.height)
                }
            }.clipped().clipShape(RoundedRectangle(cornerRadius: 22))
                .accessibilityElement(children: .contain)
                .accessibilityLabel(viewModel.selected == .initial(plantID) ? Text("detail.photo.initial") : Text("plantPhotos.add"))
                .accessibilityValue(imageValue)
                .accessibilityIdentifier(viewModel.selected == .initial(plantID) ? "detailPhoto-\(plantID)" : "plantPhotoImage-\(viewModel.selected.stableKey)")
                .contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 30).onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < 0 { viewModel.next() } else { viewModel.previous() }
                })
            Text(dateText).font(.subheadline).foregroundStyle(Color("TextSecondary"))
                .accessibilityIdentifier("plantPhotoDate-\(plantID)")
            if viewModel.isComplete, viewModel.descriptors.count > 1 {
                HStack {
                    Button { viewModel.previous() } label: { Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("plantPhotos.previous").accessibilityIdentifier("plantPhotoPrevious-\(plantID)").disabled(!viewModel.canPrevious)
                    Spacer()
                    Text("\(viewModel.index + 1) / \(viewModel.descriptors.count)").font(.caption)
                    Spacer()
                    Button { viewModel.next() } label: { Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("plantPhotos.next").accessibilityIdentifier("plantPhotoNext-\(plantID)").disabled(!viewModel.canNext)
                }
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
    private var imageValue: Text {
        switch viewModel.imageState {
        case .loaded(let image):
            if viewModel.selected == .initial(plantID) { return Text("collection.photo.loaded") }
            return Text(verbatim: String(localized: "collection.photo.loaded") + " · \(Int(image.size.width)) × \(Int(image.size.height))")
        case .failed: return Text("detail.photo.error")
        default: return Text("detail.photo.loading")
        }
    }
}
