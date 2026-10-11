import SwiftUI

/// Inline transactional editor; confirmation belongs to the shared selector.
struct ManualSpeciesView: View {
    @ObservedObject var viewModel: IdentificationPhotoViewModel
    let sessionID: UUID
    @FocusState private var focused: Bool

    private var name: Binding<String> {
        Binding(get: { viewModel.manualDraft?.id == sessionID ? viewModel.manualDraft?.name ?? "" : "" },
                set: { viewModel.updateManualName($0, sessionID: sessionID) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("manualSpecies.species")
            TextField("manualSpecies.placeholder", text: name, axis: .vertical)
                .accessibilityLabel(Text("manualSpecies.species"))
                .accessibilityIdentifier("manualSpeciesName")
                .focused($focused).submitLabel(.done).onSubmit { focused = false }
                .autocorrectionDisabled().textInputAutocapitalization(.never)
                .frame(minHeight: 44)
            Text("manualSpecies.help").font(.footnote)
            Text("manualSpecies.notice").font(.footnote)
            if viewModel.hasManualConfirmationError {
                Text("manualSpecies.error").accessibilityIdentifier("manualSpeciesError")
            }
            Button("manualSpecies.cancelEdit") { viewModel.cancelManualSpecies(sessionID: sessionID) }
                .frame(minHeight: 44).accessibilityIdentifier("cancelManualSpecies")
        }
        .foregroundStyle(Color("TextPrimary"))
        .multilineTextAlignment(.leading)
        .padding(16).background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("edit.keyboard.done") { focused = false }
                    .accessibilityIdentifier("dismissManualSpeciesKeyboard")
            }
        }
    }
}
