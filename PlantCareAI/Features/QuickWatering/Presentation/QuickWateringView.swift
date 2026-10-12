import SwiftUI

struct QuickWateringView: View {
    @StateObject var viewModel: QuickWateringViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var noteFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PlantFormHeader(name: viewModel.plant.name,
                        subtitle: String(localized: "watering.belongs"), photo: viewModel.photo)
                    VStack(alignment: .leading, spacing: 16) {
                        DatePicker(selection: Binding(get: { viewModel.occurredAt }, set: { viewModel.selectDate($0) }),
                                   in: ...viewModel.latestSelectableDate, displayedComponents: .date) {
                            Label("watering.date", systemImage: "calendar")
                        }
                        .environment(\.calendar, viewModel.calendar).environment(\.timeZone, viewModel.displayZone)
                        .accessibilityIdentifier("wateringDate")
                        HStack {
                            Spacer()
                            dayChip("watering.yesterday", offset: -1, date: viewModel.yesterday)
                            dayChip("watering.today", offset: 0, date: viewModel.today)
                        }
                        Text("watering.note").font(.subheadline.weight(.semibold))
                        TextField("", text: Binding(get: { viewModel.note }, set: { viewModel.setNote($0) }), axis: .vertical)
                            .lineLimit(3...8).focused($noteFocused)
                            .padding(12).frame(minHeight: 90, alignment: .topLeading)
                            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel(Text("watering.note")).accessibilityIdentifier("wateringNote")
                    }
                    .padding(16).background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 16))
                    .disabled(viewModel.isSaving || viewModel.state == .saved)
                    if case .error(let error) = viewModel.state {
                        Text(LocalizedStringKey(error == .validation ? "watering.validation" : error == .plantNotFound ? "watering.notFound" : "watering.error"))
                            .accessibilityIdentifier("wateringError")
                    }
                    if viewModel.isSaving { ProgressView("watering.saving").accessibilityIdentifier("wateringSaving") }
                    Button { noteFocused = false; Task { await viewModel.save() } } label: {
                        Text(LocalizedStringKey(isError ? "watering.retry" : "watering.save"))
                            .font(.body.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundStyle(.white).background(Color("PrimaryAction"), in: Capsule())
                    }
                    .buttonStyle(.plain).disabled(viewModel.isSaving || viewModel.state == .saved)
                    .accessibilityIdentifier("saveWatering")
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Color("Surface")).foregroundStyle(Color("TextPrimary"))
            .navigationTitle(Text("watering.title")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Surface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("edit.cancel").frame(minWidth: 44, minHeight: 44) }
                        .disabled(viewModel.isSaving).accessibilityIdentifier("cancelWatering")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("edit.keyboard.done") { noteFocused = false }.accessibilityIdentifier("dismissWateringKeyboard")
                }
            }
            .tint(Color("PrimaryAction"))
            .accessibilityIdentifier("wateringForm")
        }
        .presentationDetents([.fraction(0.95)]).presentationDragIndicator(.visible).presentationCornerRadius(24)
        .interactiveDismissDisabled(viewModel.isSaving)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange).receive(on: RunLoop.main)) { _ in viewModel.refreshDisplayZone() }
        .onChange(of: viewModel.state) { _, state in if state == .saved { dismiss() } }
    }

    private var isError: Bool { if case .error = viewModel.state { return true }; return false }

    private func dayChip(_ key: String, offset: Int, date: Date) -> some View {
        let selected = viewModel.calendar.isDate(viewModel.occurredAt, inSameDayAs: date)
        return Button { viewModel.selectDay(offset: offset) } label: {
            HStack(spacing: 4) {
                if selected { Image(systemName: "checkmark").accessibilityHidden(true) }
                Text(LocalizedStringKey(key))
            }
            .padding(.horizontal, 12).frame(minHeight: 44)
            .background(selected ? Color("CareMint") : Color("Surface"), in: Capsule())
        }
        .buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(offset == 0 ? "wateringToday" : "wateringYesterday")
    }
}
