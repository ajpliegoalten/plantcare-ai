import SwiftUI

struct PlantPhotoAnalysisView: View {
    @StateObject var viewModel: PlantPhotoAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let plant = viewModel.plant {
                        PlantFormHeader(name: plant.name, subtitle: plant.confirmedSpecies, photo: viewModel.image, photoSize: 56)
                    }
                    Color("SurfaceMuted").aspectRatio(4 / 3, contentMode: .fit).overlay {
                        GeometryReader { geometry in
                            if let image = viewModel.image {
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height).contentShape(Rectangle())
                            } else if viewModel.state == .failed {
                                Image(systemName: "photo.badge.exclamationmark").font(.largeTitle)
                                    .frame(width: geometry.size.width, height: geometry.size.height).accessibilityHidden(true)
                            } else { ProgressView().frame(width: geometry.size.width, height: geometry.size.height) }
                        }
                    }.clipped().clipShape(RoundedRectangle(cornerRadius: 22))
                        .accessibilityLabel("analysis.photo").accessibilityIdentifier("analysisPhoto")
                    if let date = viewModel.photoDate {
                        Text(PlantDetailViewModel.formattedDate(date, timeZone: viewModel.timeZone)).font(.subheadline)
                            .accessibilityIdentifier("analysisPhotoDate")
                    }
                    switch viewModel.state {
                    case .preparing:
                        ProgressView("analysis.preparing").frame(maxWidth: .infinity, alignment: .center)
                            .accessibilityIdentifier("analysisPreparing")
                    case .analyzing:
                        ProgressView("analysis.analyzing").frame(maxWidth: .infinity, alignment: .center)
                            .accessibilityIdentifier("analysisBusy")
                    case .awaitingConsent: Text("analysis.awaitingConsent")
                    case .failed:
                        Text(LocalizedStringKey(viewModel.errorKey)).accessibilityIdentifier("analysisError")
                        Button { viewModel.retry() } label: { Text("analysis.retry").frame(maxWidth: .infinity, minHeight: 44) }
                            .buttonStyle(.bordered).buttonBorderShape(.capsule).accessibilityIdentifier("analysisRetry")
                    case .result, .insufficientEvidence:
                        if let result = viewModel.result {
                            if result.content.outcome == .insufficientEvidence { Text("analysis.insufficient").font(.headline) }
                            section("analysis.observations", result.content.observations)
                            section("analysis.causes", result.content.possibleCauses)
                            section("analysis.checks", result.content.checks)
                            Text("analysis.provisional").font(.footnote).accessibilityIdentifier("analysisProvisional")
                            Button { viewModel.save() } label: {
                                Text("keepAnalysis.save").foregroundStyle(viewModel.canSave ? Color("Surface") : Color("TextSecondary"))
                                    .frame(maxWidth: .infinity, minHeight: 52)
                            }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                                .disabled(!viewModel.canSave).accessibilityIdentifier("analysisAccept")
                            if viewModel.saveState == .saving {
                                ProgressView("keepAnalysis.saving").accessibilityIdentifier("analysisSaving")
                            }
                            if viewModel.saveState == .failed {
                                Text(viewModel.saveNeedsNewIntent ? "keepAnalysis.stale" : "keepAnalysis.error")
                                    .accessibilityIdentifier("analysisSaveError")
                                if !viewModel.saveNeedsNewIntent {
                                    Button("keepAnalysis.retry") { viewModel.save() }.frame(minHeight: 44)
                                        .accessibilityIdentifier("analysisSaveRetry")
                                }
                            }
                            futureButton("analysis.discard", identifier: "analysisDiscard")
                            Text("keepAnalysis.discardFuture").font(.footnote).accessibilityIdentifier("analysisFutureActions")
                        }
                    }
                    #if DEBUG && targetEnvironment(simulator)
                    if let count = viewModel.invocationCount {
                        Text("Solicitudes: \(count())").font(.caption).accessibilityIdentifier("analysisInvocationCount")
                        Text(viewModel.identity.stableKey).font(.caption).accessibilityIdentifier("analysisSelectedIdentity")
                    }
                    #endif
                }.padding(20).foregroundStyle(Color("TextPrimary"))
            }.background(Color("Surface").ignoresSafeArea())
                .navigationTitle("analysis.title").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("analysis.cancel") { if viewModel.close() { dismiss() } }.frame(minHeight: 44)
                            .disabled(viewModel.saveState == .saving).accessibilityIdentifier("analysisCancel")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { if viewModel.close() { dismiss() } } label: { Image(systemName: "xmark").frame(minWidth: 44, minHeight: 44) }
                            .disabled(viewModel.saveState == .saving)
                            .accessibilityLabel("analysis.close").accessibilityIdentifier("analysisClose")
                    }
                }
        }.tint(Color("PrimaryAction")).presentationDetents([.fraction(0.95)]).presentationDragIndicator(.visible)
            .presentationCornerRadius(24).accessibilityIdentifier("analysisForm")
            .task { viewModel.start() }
            .interactiveDismissDisabled(viewModel.saveState == .saving)
            .onChange(of: viewModel.saveState) { _, state in if state == .saved { viewModel.close(); dismiss() } }
            .sheet(isPresented: $viewModel.showingConsent, onDismiss: { viewModel.cancelConsent() }) {
                ExternalAIConsentView(usesRealRecipient: true, destination: viewModel.destination, analyzingPhoto: true,
                    accept: viewModel.acceptConsent, cancel: viewModel.cancelConsent)
            }
            .onDisappear { viewModel.close() }
    }
    private func futureButton(_ title: LocalizedStringKey, identifier: String) -> some View {
        Button {} label: {
            Text(title).foregroundStyle(Color("TextSecondary"))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color("SurfaceMuted"), in: Capsule())
        }.buttonStyle(.plain).disabled(true).accessibilityIdentifier(identifier)
    }
    private func section(_ title: LocalizedStringKey, _ values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(verbatim: value).fixedSize(horizontal: false, vertical: true)
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 16))
    }
}
