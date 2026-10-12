import SwiftUI

struct PlantFormHeader: View {
    let name: String
    let subtitle: String
    let photo: UIImage?
    var photoSize: CGFloat = 48

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let photo { Image(uiImage: photo).resizable().scaledToFill() }
                else { Image(systemName: "leaf.fill").foregroundStyle(Color("Primary")) }
            }
            .frame(width: photoSize, height: photoSize).background(Color("Surface"))
            .clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.headline).accessibilityIdentifier("plantFormName")
                Text(subtitle).font(.subheadline).foregroundStyle(Color("TextSecondary"))
                    .accessibilityIdentifier("plantFormSubtitle")
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 16))
    }
}
