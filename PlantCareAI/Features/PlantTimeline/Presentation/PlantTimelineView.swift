import SwiftUI

struct PlantTimelineView: View {
    @StateObject private var viewModel: PlantTimelineViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: PlantTimelineViewModel) { _viewModel = StateObject(wrappedValue: viewModel) }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                switch viewModel.state {
                case .idle, .loading: ProgressView().frame(maxWidth: .infinity)
                case .notFound: Text("detail.notFound")
                case .failed:
                    VStack(alignment: .leading, spacing: 12) {
                        Text("timeline.error").accessibilityIdentifier("timelineError")
                        Button { viewModel.refresh() } label: { Text("timeline.retry").frame(minWidth: 44, minHeight: 44) }
                            .accessibilityIdentifier("retryTimeline")
                    }
                case .loaded:
                    if viewModel.noRecords {
                        Text("timeline.noRecords").foregroundStyle(Color("TextSecondary"))
                            .accessibilityIdentifier("timelineNoRecords")
                    } else if viewModel.noCare {
                        Text("timeline.noCare").font(.subheadline).foregroundStyle(Color("TextSecondary"))
                    }
                    ForEach(viewModel.groups) { group in
                        Text(group.title).font(.headline).accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("timelineDay-" + group.id)
                        ForEach(group.entries) { entry in
                            row(entry)
                        }
                    }
                    Text(viewModel.originIsLast ? "timeline.origin" : "timeline.first")
                        .font(.footnote).foregroundStyle(Color("TextSecondary"))
                        .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                        .accessibilityIdentifier("timelineOriginFooter")
                }
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color("TextPrimary"))
        .background(Color("Background").ignoresSafeArea())
        .navigationTitle(Text("timeline.title")).navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("plantTimeline-\(viewModel.plantID)")
        .onAppear { viewModel.appear() }
        .onDisappear { viewModel.disappear() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { viewModel.foreground() } }
    }

    private func row(_ entry: PlantTimelineEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: symbol(entry)).font(.body).foregroundStyle(Color("Primary"))
                    .frame(width: 28, height: 32)
                    .accessibilityHidden(true)
                Rectangle().fill(Color("Outline").opacity(0.5)).frame(width: 1).accessibilityHidden(true)
            }.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                switch entry {
                case .care(let event):
                    Text(title(event.kind)).font(.headline)
                    if let note = event.note { Text(note).fixedSize(horizontal: false, vertical: true) }
                case .additional:
                    Text("timeline.photograph").font(.headline)
                    TimelinePhoto(viewModel: viewModel.photos, identity: entry.id, initial: false)
                case .initial:
                    HStack(alignment: .top, spacing: 12) {
                        TimelinePhoto(viewModel: viewModel.photos, identity: entry.id, initial: true)
                            .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("timeline.added").font(.headline)
                            Text("timeline.initial").font(.subheadline)
                            Text("timeline.start").font(.footnote).foregroundStyle(Color("TextSecondary"))
                        }
                    }
                    TimelinePhotoError(viewModel: viewModel.photos, identity: entry.id)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("timelineEntry-" + entry.id.stableKey)
        }
    }

    private func title(_ kind: CareEvent.Kind) -> LocalizedStringKey {
        switch kind {
        case .watering: return "care.kind.watering"
        case .fertilizing: return "care.kind.fertilizing"
        case .pruning: return "care.kind.pruning"
        case .repotting: return "care.kind.repotting"
        case .other: return "care.kind.other"
        }
    }
    private func symbol(_ entry: PlantTimelineEntry) -> String {
        switch entry {
        case .initial: return "leaf.fill"
        case .additional: return "photo"
        case .care(let event):
            switch event.kind {
            case .watering: return "drop.fill"
            case .fertilizing: return "leaf.fill"
            case .pruning: return "scissors"
            case .repotting: return "arrow.triangle.2.circlepath"
            case .other: return "ellipsis.circle"
            }
        }
    }

    private struct TimelinePhoto: View {
        @ObservedObject var viewModel: PlantTimelinePhotoViewModel
        let identity: PlantTimelineIdentity
        let initial: Bool
        @State private var visibilityOwner = UUID()
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Color("SurfaceMuted").aspectRatio(initial ? 1 : 4 / 3, contentMode: .fit)
                    .overlay {
                        GeometryReader { geometry in
                            Group {
                                if let image = viewModel.image(for: identity) {
                                    Image(uiImage: image).resizable().scaledToFill()
                                } else if viewModel.state(for: identity) == .failed {
                                    Image(systemName: "photo.badge.exclamationmark").accessibilityHidden(true)
                                } else if viewModel.state(for: identity) == .loading {
                                    ProgressView().accessibilityLabel(Text("detail.photo.loading"))
                                } else { Image(systemName: "photo").accessibilityHidden(true) }
                            }.frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }.clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(initial ? "detail.photo.initial" : "timeline.photograph"))
                    .accessibilityIdentifier("timelinePhoto-" + identity.stableKey)
                if !initial { TimelinePhotoError(viewModel: viewModel, identity: identity) }
            }
            .onAppear { viewModel.show(identity, owner: visibilityOwner) }
            .onDisappear { viewModel.hide(identity, owner: visibilityOwner) }
        }
    }

    private struct TimelinePhotoError: View {
        @ObservedObject var viewModel: PlantTimelinePhotoViewModel
        let identity: PlantTimelineIdentity
        var body: some View {
            if viewModel.state(for: identity) == .failed {
                VStack(alignment: .leading, spacing: 8) {
                    Text("timeline.photoError").font(.footnote).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("timelinePhotoError-" + identity.stableKey)
                    Button { viewModel.retry(identity) } label: {
                        Text("timeline.retry").frame(minWidth: 44, minHeight: 44)
                    }.accessibilityIdentifier("retryTimelinePhoto-" + identity.stableKey)
                }
            }
        }
    }
}
