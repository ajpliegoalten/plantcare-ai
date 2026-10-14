import SwiftUI

struct PlantQuestionView: View {
    @StateObject var viewModel: PlantQuestionViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let plant = viewModel.plant {
                        PlantFormHeader(name: plant.name, subtitle: plant.confirmedSpecies, photo: viewModel.image, photoSize: 56)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("question.label").font(.headline)
                        TextEditor(text: $viewModel.question).focused($focused).frame(minHeight: 110)
                            .padding(12).scrollContentBackground(.hidden).background(Color("Surface"), in: RoundedRectangle(cornerRadius: 12))
                            .disabled(viewModel.busy).accessibilityLabel("question.label").accessibilityIdentifier("questionInput")
                        if viewModel.question.count > 2000 { Text("question.error.question").accessibilityIdentifier("questionLimit") }
                    }.padding(16).background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 16))
                    Button { focused = false; viewModel.send() } label: {
                        Text(viewModel.state == .failed ? "question.retry" : "question.send")
                            .font(.body.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(viewModel.canSend ? Color("Surface") : Color("TextSecondary"))
                            .background(viewModel.canSend ? Color("PrimaryAction") : Color("SurfaceMuted"), in: Capsule())
                    }.buttonStyle(.plain).disabled(!viewModel.canSend).accessibilityIdentifier("questionSend")
                    if viewModel.busy {
                        ProgressView(viewModel.state == .preparing ? "question.preparing" : viewModel.state == .awaitingConsent ? "question.awaitingConsent" : "question.asking")
                            .frame(maxWidth: .infinity).accessibilityIdentifier("questionBusy")
                        Button("question.cancelRequest") { viewModel.cancelRequest() }.frame(minHeight: 44).accessibilityIdentifier("questionCancelRequest")
                    }
                    if viewModel.state == .failed { Text(LocalizedStringKey(viewModel.errorKey)).accessibilityIdentifier("questionError") }
                    if let result = viewModel.result {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("question.answer").font(.headline).accessibilityAddTraits(.isHeader)
                            Text(verbatim: result.question).font(.subheadline).accessibilityIdentifier("questionAnsweredPrompt")
                            Text(verbatim: result.answer.answer).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("questionAnswer")
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 16))
                    }
                    Text("question.disclaimer").font(.footnote).foregroundStyle(Color("TextSecondary")).accessibilityIdentifier("questionDisclaimer")
                    #if DEBUG && targetEnvironment(simulator)
                    if let count = viewModel.invocationCount { Text("Solicitudes: \(count())").accessibilityIdentifier("questionInvocationCount") }
                    #endif
                }.padding(20).foregroundStyle(Color("TextPrimary"))
            }.background(Color("Surface").ignoresSafeArea()).navigationTitle("question.title").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("question.cancel") { viewModel.close(); dismiss() }.frame(minHeight: 44).accessibilityIdentifier("questionClose")
                    }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("question.done") { focused = false } }
                }
        }.tint(Color("PrimaryAction")).presentationDetents([.fraction(0.95)]).presentationDragIndicator(.visible).presentationCornerRadius(24)
            .accessibilityIdentifier("questionForm")
            .sheet(isPresented: $viewModel.showingConsent, onDismiss: { viewModel.cancelConsent() }) {
                ExternalAIConsentView(usesRealRecipient: true, destination: viewModel.destination, questioningPlant: true, accept: viewModel.acceptConsent, cancel: viewModel.cancelConsent)
            }
            .onChange(of: viewModel.closed) { _, closed in if closed { dismiss() } }
            .onDisappear { viewModel.close() }
    }
}
