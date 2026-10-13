import SwiftUI

struct PlantTimelineView: View {
    @StateObject private var viewModel: PlantTimelineViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: PlantTimelineViewModel) { _viewModel = StateObject(wrappedValue: viewModel) }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.deletionState == .failed { deletionBanner }
            if viewModel.deletionState == .deleting {
                ProgressView("timeline.delete.busy").padding().accessibilityIdentifier("deletionBusy")
            }
        GeometryReader { viewport in
        ScrollView {
            // Metadata views are lightweight; image IO still follows the actual
            // viewport (cache3/concurrency2). Avoid iOS26 lazy estimate loops on
            // long rows invalidated by native alerts.
            VStack(alignment: .leading, spacing: 20) {
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
        .coordinateSpace(name: "plantTimelineViewport")
        .onPreferenceChange(PhotoFrames.self) { frames in
            viewModel.photos.scheduleViewport(frames: frames, bounds: CGRect(origin: .zero, size: viewport.size))
        }
        }
        .accessibilityIdentifier("plantTimeline-\(viewModel.plantID)")
        }
        .navigationTitle(Text("timeline.title")).navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.deletionState == .deleting)
        .alert(viewModel.deletionIsPhoto ? Text("timeline.delete.photo.title") : Text("timeline.delete.care.title"),
               isPresented: $viewModel.showingDeletionConfirmation) {
            Button("timeline.delete.cancel", role: .cancel) { viewModel.abandonDeletion() }
            Button("timeline.delete.confirm", role: .destructive) { viewModel.confirmDeletion() }
        } message: {
            Text(viewModel.deletionContext + "\n\n" + String(localized: viewModel.deletionIsPhoto ? "timeline.delete.photo.message" : "timeline.delete.care.message"))
        }
        .onAppear { viewModel.appear() }
        .sheet(item: $viewModel.analysisEditor) { PlantPhotoAnalysisView(viewModel: $0) }
        .onDisappear { if viewModel.analysisEditor == nil { viewModel.disappear() } }
        .onChange(of: scenePhase) { _, phase in if phase == .active { viewModel.foreground() } }
    }


    private func row(_ entry: PlantTimelineEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol(entry)).font(.body).foregroundStyle(Color("Primary"))
                .frame(width: 28, height: 32).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                switch entry {
                case .care(let event):
                    deletionHeader(entry, title: title(event.kind))
                    if let note = event.note { Text(note).fixedSize(horizontal: false, vertical: true) }
                case .additional:
                    deletionHeader(entry, title: "timeline.photograph")
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
                    analysisButton(entry)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("timelineEntry-" + entry.id.stableKey)
        }
        // Decoration must not compete with a long card for an unbounded height
        // during LazyVStack's estimated-size pass. A background never sizes the row.
        .background {
            Connector().stroke(Color("Outline").opacity(0.5), lineWidth: 1)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
    }

    private struct Connector: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            guard rect.height > 32 else { return path }
            path.move(to: CGPoint(x: 14, y: 32))
            path.addLine(to: CGPoint(x: 14, y: rect.height))
            return path
        }
    }

    private func deletionHeader(_ entry: PlantTimelineEntry, title: LocalizedStringKey) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer(minLength: 8)
            if entry.isPhoto { analysisButton(entry) }
            Button { viewModel.requestDeletion(entry) } label: {
                // One-point margin avoids a transformed AX frame rounding below44pt.
                Image(systemName: "trash").frame(minWidth: 45, minHeight: 45)
            }
            .foregroundStyle(Color("TextSecondary"))
            .accessibilityLabel(entry.isPhoto ? Text("timeline.delete.photo.accessibility") :
                Text("timeline.delete.care.accessibility") + Text(" ") + Text(title))
            .accessibilityIdentifier("deleteTimeline-" + entry.id.stableKey)
            .disabled(viewModel.deletionState != .idle)
        }
    }

    @ViewBuilder private func analysisButton(_ entry: PlantTimelineEntry) -> some View {
        if viewModel.makeAnalysis != nil {
            Button { viewModel.requestAnalysis(entry) } label: {
                Label("analysis.open", systemImage: "sparkles").font(.subheadline).frame(minHeight: 45)
            }.accessibilityIdentifier("analyzeTimeline-" + entry.id.stableKey)
                .disabled(viewModel.deletionState != .idle || viewModel.analysisEditor != nil)
        }
    }

    private var deletionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: "exclamationmark.triangle.fill").accessibilityHidden(true)
                Text(viewModel.deletionIsPhoto ? "timeline.delete.photo.error" : "timeline.delete.care.error").font(.headline)
                Spacer()
                Button { viewModel.abandonDeletion() } label: {
                    Image(systemName: "xmark").frame(minWidth: 45, minHeight: 45)
                }.accessibilityLabel(Text("timeline.delete.close")).accessibilityIdentifier("closeDeletionError")
            }
            Text(viewModel.deletionReadFailed ? "timeline.delete.readFailure" : (viewModel.deletionNeedsReconciliation ? "timeline.delete.stale" :
                    (viewModel.deletionIsPhoto ? (viewModel.deletionPhotoWasReadable ? "timeline.delete.photo.rollback" : "timeline.delete.photo.recordRetained") : "timeline.delete.care.rollback")))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                if !viewModel.deletionNeedsReconciliation {
                    Button("timeline.delete.retry") { viewModel.confirmDeletion() }
                        .frame(minHeight: 45).accessibilityIdentifier("retryDeletion")
                }
                Button("timeline.delete.cancel") { viewModel.abandonDeletion() }
                    .frame(minHeight: 45).accessibilityIdentifier("cancelDeletionError")
            }
            .foregroundStyle(Color("PrimaryAction"))
        }
        .padding(16).foregroundStyle(Color("TextPrimary"))
        .background(Color("SurfaceMuted"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("deletionError")
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

    private struct PhotoFrames: PreferenceKey {
        static var defaultValue: [PlantTimelineIdentity: CGRect] { [:] }
        static func reduce(value: inout [PlantTimelineIdentity: CGRect], nextValue: () -> [PlantTimelineIdentity: CGRect]) {
            value.merge(nextValue(), uniquingKeysWith: { _, new in new })
        }
    }

    private struct TimelinePhoto: View {
        @ObservedObject var viewModel: PlantTimelinePhotoViewModel
        let identity: PlantTimelineIdentity
        let initial: Bool
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
                                 // scaledToFill can extend beyond the visible crop;
                                 // clipping alone does not constrain hit testing.
                                 // A portrait must not intercept its trash header.
                                 .contentShape(Rectangle())
                        }
                    }.clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(key: PhotoFrames.self,
                                value: [identity: geometry.frame(in: .named("plantTimelineViewport"))])
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(initial ? "detail.photo.initial" : "timeline.photograph"))
                    .accessibilityValue(imageValue)
                    .accessibilityIdentifier("timelinePhoto-" + identity.stableKey)
                if !initial { TimelinePhotoError(viewModel: viewModel, identity: identity) }
            }
        }
        private var imageValue: Text {
            if viewModel.image(for: identity) != nil { return Text("collection.photo.loaded") }
            if viewModel.state(for: identity) == .failed { return Text("detail.photo.error") }
            return Text("detail.photo.loading")
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
