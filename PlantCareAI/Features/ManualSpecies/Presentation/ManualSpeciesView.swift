import SwiftUI

struct ManualSpeciesView: View {
    @ObservedObject var viewModel: IdentificationPhotoViewModel
    let sessionID: UUID
    @FocusState private var focused: Bool

    private var name: Binding<String> {
        Binding(get: { viewModel.manualDraft?.id == sessionID ? viewModel.manualDraft?.name ?? "" : "" },
                set: { viewModel.updateManualName($0, sessionID: sessionID) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        if let photo = viewModel.photo, let image = UIImage(data: photo.jpeg) {
                            Image(uiImage: image).resizable().scaledToFit().frame(width: 64, height: 64)
                                .accessibilityLabel(Text("identificationPhoto.preview"))
                        }
                        VStack(alignment: .leading) {
                            Text("manualSpecies.currentDraft").font(.headline)
                            Text("manualSpecies.provenance").font(.subheadline)
                        }
                    }
                }.listRowBackground(Color("Surface"))
                Section {
                    VStack(alignment: .leading) {
                        Text("manualSpecies.species")
                        TextField("manualSpecies.placeholder", text: name, axis: .vertical)
                            .accessibilityLabel(Text("manualSpecies.species"))
                            .accessibilityIdentifier("manualSpeciesName")
                            .focused($focused).submitLabel(.done).onSubmit { focused = false }
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                            .frame(minHeight: 44)
                    }
                    Text("manualSpecies.help").font(.footnote)
                }.listRowBackground(Color("Surface"))
                if viewModel.hasManualConfirmationError {
                    Text("manualSpecies.error").accessibilityIdentifier("manualSpeciesError")
                        .listRowBackground(Color("Surface"))
                }
                Section {
                    Button { viewModel.confirmManualSpecies(sessionID: sessionID) } label: {
                        Text("confirmSpecies.confirm").frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(name.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                             ? Color("TextSecondary") : Color("Surface"))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("confirmManualSpecies")
                    Text("manualSpecies.notice").font(.footnote)
                }.listRowBackground(Color("Surface"))
            }
            .scrollContentBackground(.hidden).scrollDismissesKeyboard(.immediately)
            .background(Color("Background")).foregroundStyle(Color("TextPrimary"))
            .navigationTitle("manualSpecies.title").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { viewModel.cancelManualSpecies(sessionID: sessionID) } label: {
                        Text("identificationPhoto.cancel").frame(minWidth: 44, minHeight: 44)
                    }.accessibilityIdentifier("cancelManualSpecies")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("edit.keyboard.done") { focused = false }
                        .accessibilityIdentifier("dismissManualSpeciesKeyboard")
                }
            }
        }
        .tint(Color("PrimaryAction"))
        .presentationDetents([.fraction(0.95)]).presentationDragIndicator(.visible)
        .onDisappear { viewModel.cancelManualSpecies(sessionID: sessionID) }
    }
}
