#if DEBUG && targetEnvironment(simulator)
import Foundation
import UIKit

// Simulator Debug only. Separate store, explicitly selected by test arguments; never production seed data.
enum StorageTestFixture {
    static func plant(_ index: Int) -> Plant {
        let longText = ProcessInfo.processInfo.arguments.contains("--storage-long-text")
        let longCare = ProcessInfo.processInfo.arguments.contains("--storage-long-care")
        func care(_ label: String) -> String {
            "\(label) \(index)" + (longCare ? ": orientación guardada únicamente para este ejemplar. Comprueba sus condiciones antes de actuar y adapta los cuidados con prudencia, sin interpretar esta ficha como un diagnóstico." : "")
        }
        return Plant(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index)")!,
              name: longText ? "Fixture \(index): mi planta junto a la ventana del salón" : "Fixture \(index)",
              confirmedSpecies: longText ? "Monstera deliciosa — especie confirmada de este ejemplar" : "Monstera deliciosa",
              createdAt: Date(timeIntervalSince1970: Double(index) * 1000),
              location: index == 1 ? (longText ? "Ventana del salón junto a la estantería de libros" : "Ventana") : nil,
              careSheet: CareSheet(light: care("Luz"), watering: care("Riego"),
                                   humidity: care("Humedad"), temperature: care("Temperatura"),
                                   substrate: care("Sustrato"), fertilizer: care("Abono")))
    }

    static func photo(_ index: Int) -> Data {
        // Locally drawn test motif, not stock photography or production seed data.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 640, height: 480), format: format).image { context in
            (index == 1 ? UIColor(red: 0.85, green: 0.45, blue: 0.55, alpha: 1) : UIColor(red: 0.25, green: 0.65, blue: 0.7, alpha: 1)).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 640, height: 480))
            UIColor.brown.setFill()
            context.fill(CGRect(x: 240, y: 320, width: 160, height: 120))
            UIColor.darkGray.setStroke()
            context.cgContext.setLineWidth(12)
            context.cgContext.move(to: CGPoint(x: 320, y: 330))
            context.cgContext.addLine(to: CGPoint(x: index == 1 ? 260 : 380, y: 100))
            context.cgContext.strokePath()
            UIColor.green.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: index == 1 ? 160 : 300, y: 110, width: 180, height: 90))
        }.jpegData(compressionQuality: 0.9)!
    }
}

struct StorageFixtureLoad: LoadPlantsUseCase {
    let root: URL
    let repository: LocalPlantRepository
    let seed: Bool
    let corrupt: Bool

    func execute() async throws -> [Plant] {
        if ProcessInfo.processInfo.arguments.contains("--storage-cleanup") {
            try? FileManager.default.removeItem(at: root)
            return []
        }
        if seed || corrupt { try? FileManager.default.removeItem(at: root) }
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
        if ProcessInfo.processInfo.arguments.contains("--storage-photo-missing") {
            try? FileManager.default.removeItem(at: root.appendingPathComponent("Photos").appendingPathComponent("\(StorageTestFixture.plant(1).id).jpg"))
        }
        return plants
    }
}
#endif
