import SwiftUI

struct PlantListView: View {
    @ObservedObject var viewModel: PlantListViewModel
    @State private var photoDraft: IdentificationPhotoViewModel?
    @State private var path = NavigationPath()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            switch viewModel.state {
                            case .loading:
                                ProgressView()
                            case .loaded(let plants) where plants.isEmpty:
                                EmptyPlantView(onAdd: openPhoto)
                            case .loaded:
                                LazyVStack(spacing: 24) {
                                    ForEach(viewModel.cards) { card in
                                        PlantCardView(viewModel: card)
                                            .id(card.id)
                                    }
                                }
                            case .failed:
                                statusMessage("collection.storageError", identifier: "storageErrorMessage")
                                Button("savePlant.retryRead") { Task { await viewModel.retryLoad() } }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .frame(minHeight: geometry.size.height, alignment: contentAlignment)
                    }
                    .accessibilityIdentifier("collectionViewport")
                    .onChange(of: photoDraft == nil) { _, closed in
                        if closed, let id = viewModel.newlyAddedPlantID { proxy.scrollTo(id, anchor: .bottom) }
                    }
                    .onChange(of: viewModel.cards.count) { _, _ in
                        if photoDraft == nil, let id = viewModel.newlyAddedPlantID { proxy.scrollTo(id, anchor: .bottom) }
                    }
                    }
                }
            }
            .background(Color("Background").ignoresSafeArea())
            .overlay(alignment: .bottom) {
                #if DEBUG && targetEnvironment(simulator)
                if photoDraft == nil {
                    VStack {
                        if let count = viewModel.lastCareInvocationCount { Text("Care invocations: \(count)").accessibilityIdentifier("careSheetInvocationCount") }
                        if let count = viewModel.lastIdentificationInvocationCount { Text("Instrumented invocations: \(count)").accessibilityIdentifier("externalAIInvocationCount") }
                    }
                }
                #endif
            }
            .task { await viewModel.load() }
            .navigationDestination(for: UUID.self) { id in
                PlantDetailView(viewModel: viewModel.detailViewModel(id: id), isCoveredByHistory: { path.count > 1 }).id(id)
            }
            .navigationDestination(for: PlantTimelineRoute.self) { route in
                if let timeline = viewModel.makeTimeline?(route.plantID) {
                    PlantTimelineView(viewModel: timeline).id(route.plantID)
                }
            }
            .sheet(item: Binding(get: { photoDraft }, set: { newValue in
                if newValue == nil { photoDraft?.close() }
                if newValue == nil, photoDraft?.canClose == false { return }
                photoDraft = newValue
            })) { draft in
                IdentificationPhotoView(viewModel: draft)
            }
        }
        .onChange(of: viewModel.deletionEvent) { _, event in
            if event != nil { path = NavigationPath() }
        }
    }

    private var contentAlignment: Alignment {
        if case .loaded(let plants) = viewModel.state, !plants.isEmpty {
            return .top
        }
        return .center
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
