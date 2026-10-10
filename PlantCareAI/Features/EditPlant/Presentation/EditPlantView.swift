import SwiftUI

struct EditPlantView: View {
    @StateObject var viewModel: EditPlantViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?
    private enum Field { case name, location }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Text("edit.name")
                        TextField("", text: $viewModel.name, axis: .vertical)
                            .accessibilityLabel(Text("edit.name"))
                            .accessibilityIdentifier("editPlantName")
                            .focused($focus, equals: .name).submitLabel(.next)
                            .onSubmit { focus = .location }
                            .frame(minHeight: 44)
                    }
                    VStack(alignment: .leading) {
                        Text("edit.location")
                        TextField("", text: $viewModel.location, axis: .vertical)
                            .accessibilityLabel(Text("edit.location"))
                            .accessibilityIdentifier("editPlantLocation")
                            .focused($focus, equals: .location).submitLabel(.done)
                            .onSubmit { focus = nil }
                            .frame(minHeight: 44)
                    }
                }
                .listRowBackground(Color("Surface"))
                .disabled(viewModel.isSaving)
                if !viewModel.isValid {
                    Text("edit.validation").accessibilityIdentifier("editPlantValidation")
                        .listRowBackground(Color("Surface"))
                }
                if case .error(let error) = viewModel.state {
                    Text(LocalizedStringKey(error == .notFound ? "edit.notFound" : "edit.error"))
                        .accessibilityIdentifier("editPlantError")
                        .listRowBackground(Color("Surface"))
                }
                if viewModel.isSaving { ProgressView("edit.saving").listRowBackground(Color("Surface")) }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(Color("Background"))
            .foregroundStyle(Color("TextPrimary"))
            .navigationTitle(Text("edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("edit.cancel").frame(minWidth: 44, minHeight: 44) }
                        .disabled(viewModel.isSaving).accessibilityIdentifier("cancelEditPlant")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await viewModel.save() } } label: { Text("edit.save").frame(minWidth: 44, minHeight: 44) }
                        .disabled(!viewModel.isValid || viewModel.isSaving || viewModel.state == .saved)
                        .accessibilityIdentifier("saveEditPlant")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("edit.keyboard.done") { focus = nil }
                        .accessibilityIdentifier("dismissEditPlantKeyboard")
                }
            }
            .tint(Color("PrimaryAction"))
            .accessibilityIdentifier("editPlantForm-\(viewModel.id)")
        }
        .interactiveDismissDisabled(viewModel.isSaving)
        .presentationDetents([.fraction(0.95)])
        .presentationDragIndicator(.visible)
        .onChange(of: viewModel.state) { _, state in if state == .saved { dismiss() } }
    }
}
