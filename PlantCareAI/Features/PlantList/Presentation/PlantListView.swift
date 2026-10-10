import SwiftUI

struct PlantListView: View {
    @ObservedObject var viewModel: PlantListViewModel
    @State private var photoDraft: IdentificationPhotoViewModel?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        header

                        switch viewModel.state {
                        case .loading:
                            ProgressView()
                        case .loaded(let plants) where plants.isEmpty:
                            Spacer(minLength: 32)
                            EmptyPlantView(onAdd: openPhoto)
                            Spacer(minLength: 32)
                        case .loaded:
                            LazyVStack(spacing: 24) {
                                ForEach(viewModel.cards) { card in
                                    PlantCardView(viewModel: card)
                                }
                            }
                        case .failed:
                            Spacer(minLength: 32)
                            statusMessage("collection.storageError", identifier: "storageErrorMessage")
                            Spacer(minLength: 32)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color("Background").ignoresSafeArea())
            .task { await viewModel.load() }
            .navigationDestination(for: UUID.self) { id in
                PlantDetailView(viewModel: viewModel.detailViewModel(id: id)).id(id)
            }
            .sheet(item: Binding(get: { photoDraft }, set: { newValue in
                if newValue == nil { photoDraft?.close() }
                photoDraft = newValue
            })) { draft in
                IdentificationPhotoView(viewModel: draft)
            }
        }
    }

    private func statusMessage(_ key: LocalizedStringKey, identifier: String) -> some View {
        Text(key)
            .font(.body)
            .foregroundStyle(Color("TextSecondary"))
            .multilineTextAlignment(.center)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
            .accessibilityIdentifier(identifier)
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    collectionTitle
                    headerAddButton
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    collectionTitle
                    Spacer(minLength: 0)
                    headerAddButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }

    private var collectionTitle: some View {
        Text("collection.title")
            .font(.largeTitle.bold())
            .foregroundStyle(Color("Primary"))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("collectionTitle")
    }

    private var headerAddButton: some View {
        Button(action: openPhoto) {
            Label("collection.add", systemImage: "plus")
                .font(.body.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
        }
        .foregroundStyle(Color("PrimaryAction"))
        .accessibilityIdentifier("addPlantHeader")
    }

    private func openPhoto() {
        photoDraft = viewModel.makeIdentificationPhoto?()
    }
}
