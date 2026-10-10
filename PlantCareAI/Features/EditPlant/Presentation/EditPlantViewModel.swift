import Foundation

@MainActor
final class EditPlantViewModel: ObservableObject, Identifiable {
    enum State: Equatable { case editing, saving, error(PlantStorageError), saved }
    let id: UUID
    @Published var name: String
    @Published var location: String
    @Published private(set) var state: State = .editing
    private let update: UpdatePlant
    private let onSaved: @MainActor (Plant) -> Void

    init(plant: Plant, update: UpdatePlant, onSaved: @escaping @MainActor (Plant) -> Void) {
        id = plant.id
        name = plant.name
        location = plant.location ?? ""
        self.update = update
        self.onSaved = onSaved
    }

    var isValid: Bool { (try? UpdatePlant.normalized(name: name, location: location)) != nil }
    var isSaving: Bool { state == .saving }

    func save() async {
        guard isValid, !isSaving, state != .saved else { return }
        let name = name, location = location
        state = .saving
        do {
            let plant = try await update.execute(id: id, name: name, location: location)
            onSaved(plant)
            state = .saved
        } catch {
            state = .error((error as? PlantStorageError) ?? .storage)
        }
    }
}
