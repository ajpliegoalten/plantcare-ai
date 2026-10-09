import SwiftUI

struct ContentView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    header

                    Spacer(minLength: 32)

                    emptyCard

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

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf")
                .font(.largeTitle)
                .foregroundStyle(Color("Primary"))
                .accessibilityHidden(true)

            Text("collection.empty.title")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color("TextPrimary"))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("emptyCollectionTitle")

            Text("collection.empty.body")
                .font(.body)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)

            Button(action: {}) {
                Text("collection.empty.add")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 12)
            }
            .foregroundStyle(Color("Surface"))
            .background(Color("PrimaryAction"), in: RoundedRectangle(cornerRadius: 12))
            .disabled(true)
            .accessibilityHint(Text("collection.add.unavailable"))
            .accessibilityIdentifier("addFirstPlant")

            Text("collection.add.unavailable")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 22))
    }
}
