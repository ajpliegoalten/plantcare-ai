import SwiftUI

struct PlantListView: View {
    @ObservedObject var viewModel: PlantListViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    header

                    Spacer(minLength: 32)

                    if viewModel.plants.isEmpty {
                        EmptyPlantView()
                    }

                    Spacer(minLength: 32)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, 20)
            }
        }
        .background(Color("Background").ignoresSafeArea())
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
        Button(action: {}) {
            Label("collection.add", systemImage: "plus")
                .font(.body.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
        }
        .foregroundStyle(Color("PrimaryAction"))
        .disabled(true)
        .accessibilityHint(Text("collection.add.unavailable"))
        .accessibilityIdentifier("addPlantHeader")
    }
}
