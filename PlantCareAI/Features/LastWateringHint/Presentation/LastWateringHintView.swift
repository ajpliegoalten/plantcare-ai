import SwiftUI

struct LastWateringHintView: View {
    enum Style { case compactCard, detailRow }
    @ObservedObject var viewModel: LastWateringHintViewModel
    let style: Style

    var body: some View {
        if case .loaded(let date) = viewModel.state, let value = viewModel.value(compact: style == .compactCard) {
            Group {
                if style == .compactCard {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: date == nil ? "drop" : "drop.fill").font(.body).accessibilityHidden(true)
                        Text(value).font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color(date == nil ? "TextSecondary" : "Primary"))
                } else {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: date == nil ? "drop" : "drop.fill")
                            .foregroundStyle(Color(date == nil ? "TextSecondary" : "Primary"))
                            .frame(width: 36, height: 36)
                            .background(Color(date == nil ? "Surface" : "CareMint"), in: Circle())
                            .accessibilityHidden(true)
                        if date == nil {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("lastWatering.title").font(.subheadline.weight(.semibold))
                                Text(value).font(.subheadline).foregroundStyle(Color("TextSecondary"))
                            }
                        } else {
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("lastWatering.title").font(.subheadline.weight(.semibold))
                                    Spacer(minLength: 12)
                                    Text(value).font(.subheadline).foregroundStyle(Color("Primary"))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("lastWatering.title").font(.subheadline.weight(.semibold))
                                    Text(value).font(.subheadline).foregroundStyle(Color("Primary"))
                                }
                            }
                        }
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("lastWatering.title"))
            .accessibilityValue(value)
            .accessibilityIdentifier("\(style == .compactCard ? "card" : "detail")LastWatering-\(viewModel.plantID)")
        }
    }
}
