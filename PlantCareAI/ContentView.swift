import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("bootstrap.title")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("Primary"))
                .accessibilityIdentifier("bootstrapTitle")

            Text("bootstrap.subtitle")
                .font(.body)
                .foregroundStyle(Color("TextPrimary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(20)
        .background(Color("Background").ignoresSafeArea())
    }
}
