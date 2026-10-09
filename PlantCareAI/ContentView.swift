import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PlantCare AI")
                .font(.largeTitle.bold())
                .foregroundStyle(Color(red: 38 / 255, green: 77 / 255, blue: 60 / 255))
                .accessibilityIdentifier("bootstrapTitle")

            Text("Preparando tu espacio para cuidar plantas.")
                .font(.body)
                .foregroundStyle(Color(red: 25 / 255, green: 28 / 255, blue: 24 / 255))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(20)
        .background(Color(red: 248 / 255, green: 250 / 255, blue: 242 / 255).ignoresSafeArea())
    }
}
