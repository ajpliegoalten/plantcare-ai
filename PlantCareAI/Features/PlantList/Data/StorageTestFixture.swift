#if DEBUG && targetEnvironment(simulator)
import Foundation
import UIKit

// Simulator Debug only. Separate store, explicitly selected by test arguments; never production seed data.
enum StorageTestFixture {
    static func plant(_ index: Int) -> Plant {
        Plant(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index)")!,
              name: "Fixture \(index)", confirmedSpecies: "Monstera deliciosa",
              createdAt: Date(timeIntervalSince1970: Double(index) * 1000),
              location: index == 1 ? "Ventana" : nil,
              careSheet: CareSheet(light: "Luz \(index)", watering: "Riego \(index)",
                                   humidity: "Humedad \(index)", temperature: "Temperatura \(index)",
                                   substrate: "Sustrato \(index)", fertilizer: "Abono \(index)"))
    }

    static func photo(_ index: Int) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            (index == 1 ? UIColor.red : UIColor.green).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }.jpegData(compressionQuality: 0.9)!
    }
}

struct StorageFixtureLoad: LoadPlantsUseCase {
    let root: URL
    let seed: Bool
    let corrupt: Bool

    func execute() async throws -> [Plant] {
        if ProcessInfo.processInfo.arguments.contains("--storage-cleanup") {
            try? FileManager.default.removeItem(at: root)
            return []
        }
        if seed || corrupt { try? FileManager.default.removeItem(at: root) }
        let repository = LocalPlantRepository(root: root)
        if corrupt {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            try Data("invalid store".utf8).write(to: root.appendingPathComponent("Plants.store"))
        }
        if seed {
            for index in 1...2 {
                try await SavePlant(repository: repository).execute(StorageTestFixture.plant(index), initialPhoto: StorageTestFixture.photo(index))
            }
        }
        let plants = try await repository.loadPlants()
        if seed || ProcessInfo.processInfo.arguments.contains("--storage-verify") {
            guard plants == (1...2).map(StorageTestFixture.plant) else { throw PlantStorageError.storage }
            for index in 1...2 {
                let bytes = try await repository.loadInitialPhoto(for: StorageTestFixture.plant(index).id)
                guard bytes == StorageTestFixture.photo(index) else { throw PlantStorageError.photoCorrupt }
            }
        }
        return plants
    }
}
#endif
