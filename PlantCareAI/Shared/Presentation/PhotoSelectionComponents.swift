import SwiftUI

/// Presentation-only components shared by identification and local photo import.
struct PhotoSelectionPreview: View {
    let image: UIImage?
    let previewID: String
    let placeholderID: String
    let value: String
    var previewLabel: LocalizedStringKey = "identificationPhoto.preview"

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).fill(Color("Surface"))
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
                    .accessibilityLabel(Text(previewLabel))
                    .accessibilityIdentifier(previewID)
                    .accessibilityValue(value)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "leaf").font(.largeTitle).accessibilityHidden(true)
                    Text("identificationPhoto.placeholder")
                }.padding(20).accessibilityIdentifier(placeholderID)
            }
        }
        .foregroundStyle(Color("TextSecondary"))
        .multilineTextAlignment(.center)
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct PhotoActionLabel: View {
    let title: LocalizedStringKey
    let symbol: String
    var prominent = false
    var enabled = true

    var body: some View {
        Label(title, systemImage: symbol)
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(enabled ? (prominent ? Color("Surface") : Color("PrimaryAction")) : Color("TextSecondary"))
    }
}

struct PhotoActionsSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 16) { content }
            .padding(16)
            .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color("Outline"), lineWidth: 1))
    }
}
