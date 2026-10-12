import SwiftUI

struct RegisterCareView: View {
    @StateObject var viewModel: RegisterCareViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var noteFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PlantFormHeader(name: viewModel.plant.name,
                        subtitle: String(localized: "care.belongs"), photo: viewModel.photo, photoSize: 56)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("care.kind").font(.subheadline.weight(.semibold))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(CareEvent.Kind.allCases, id: \.self) { kind in kindButton(kind) }
                        }
                        DatePicker(selection: Binding(get: { viewModel.occurredAt }, set: { viewModel.selectDate($0) }),
                                   in: ...viewModel.latestSelectableDate, displayedComponents: .date) {
                            Label("care.date", systemImage: "calendar")
                        }
                        .environment(\.calendar, viewModel.calendar).environment(\.timeZone, viewModel.displayZone)
                        .environment(\.locale, Locale(identifier: "es_ES")).datePickerStyle(.compact)
                        .accessibilityIdentifier("careDate")
                        HStack {
                            Spacer()
                            dayChip("care.yesterday", offset: -1, date: viewModel.yesterday)
                            dayChip("care.today", offset: 0, date: viewModel.today)
                        }
                        Text("care.note").font(.subheadline.weight(.semibold))
                        TextEditor(text: Binding(get: { viewModel.note }, set: { viewModel.setNote($0) }))
                            .focused($noteFocused).scrollContentBackground(.hidden)
                            .padding(8).frame(height: 110)
                            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel(Text("care.note")).accessibilityIdentifier("careNote")
                    }
                    .padding(16).background(Color("SurfaceMuted"), in: RoundedRectangle(cornerRadius: 16))
                    .disabled(viewModel.isSaving || viewModel.state == .saved)
                    if case .error(let error) = viewModel.state {
                        Text(LocalizedStringKey(error == .validation ? "care.validation" : error == .plantNotFound ? "care.notFound" : "care.error"))
                            .accessibilityIdentifier("careError")
                    }
                    if viewModel.isSaving { ProgressView("care.saving").accessibilityIdentifier("careSaving") }
                    Button { noteFocused = false; Task { await viewModel.save() } } label: {
                        Text(LocalizedStringKey(isError ? "care.retry" : "care.save"))
                            .font(.body.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(viewModel.canSave ? Color.white : Color("TextSecondary"))
                            .background(viewModel.canSave ? Color("PrimaryAction") : Color("SurfaceMuted"), in: Capsule())
                    }
                    .buttonStyle(.plain).disabled(!viewModel.canSave)
                    .accessibilityIdentifier("saveCare")
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Color("Surface")).foregroundStyle(Color("TextPrimary"))
            .navigationTitle(Text("care.title")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Surface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("edit.cancel").frame(minWidth: 44, minHeight: 44) }
                        .disabled(viewModel.isSaving).accessibilityIdentifier("cancelCare")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("edit.keyboard.done") { noteFocused = false }.accessibilityIdentifier("dismissCareKeyboard")
                }
            }
            .tint(Color("PrimaryAction"))
            .accessibilityIdentifier("careForm")
        }
        .presentationDetents([.fraction(0.95)]).presentationDragIndicator(.visible).presentationCornerRadius(24)
        .interactiveDismissDisabled(viewModel.isSaving)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange).receive(on: RunLoop.main)) { _ in viewModel.refreshDisplayZone() }
        .onChange(of: viewModel.state) { _, state in if state == .saved { dismiss() } }
    }

    private var isError: Bool { if case .error = viewModel.state { return true }; return false }

    private func kindButton(_ kind: CareEvent.Kind) -> some View {
        let selected = viewModel.selectedKind == kind
        return Button { viewModel.selectKind(kind) } label: {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: symbol(kind))
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").opacity(selected ? 1 : 0)
                }
                .accessibilityHidden(true)
                Text(title(kind))
                    .font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .foregroundStyle(selected ? Color("PrimaryAction") : Color("TextPrimary"))
            .background(selected ? Color("CareMint") : Color("Surface"), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color("PrimaryAction") : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("careKind-\(kind.rawValue)")
    }

    private func symbol(_ kind: CareEvent.Kind) -> String {
        switch kind {
        case .watering: return "drop.fill"
        case .fertilizing: return "leaf.fill"
        case .pruning: return "scissors"
        case .repotting: return "arrow.triangle.2.circlepath"
        case .other: return "ellipsis.circle"
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
        .accessibilityIdentifier(offset == 0 ? "careToday" : "careYesterday")
    }
}
