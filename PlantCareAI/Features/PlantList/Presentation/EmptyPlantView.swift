import SwiftUI

struct EmptyPlantView: View {
    var body: some View {
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
