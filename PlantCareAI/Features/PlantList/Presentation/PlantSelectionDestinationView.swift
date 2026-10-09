import SwiftUI

// plant-detail will replace this shell, preserving the selected UUID route.
struct PlantSelectionDestinationView: View {
    let plant: Plant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(plant.name)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("Primary"))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("selectedPlant-\(plant.id)")
                Text("collection.selection.pending")
                    .font(.body)
                    .foregroundStyle(Color("TextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Color("Background").ignoresSafeArea())
    }
}
