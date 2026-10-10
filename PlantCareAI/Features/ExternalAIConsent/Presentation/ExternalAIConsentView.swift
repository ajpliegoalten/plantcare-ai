import SwiftUI

struct ExternalAIConsentView: View {
    let accept: () -> Void
    let cancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("externalAIConsent.body").accessibilityIdentifier("externalAIConsentBody")
                    Text("externalAIConsent.notAvailable").font(.callout)
                        .accessibilityIdentifier("externalAIConsentCurrentLimit")
                    Button(action: accept) {
                        Text("externalAIConsent.accept")
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(Color("Surface"))
                    }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("acceptExternalAIConsent")
                }.padding(20).foregroundStyle(Color("TextPrimary"))
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle("externalAIConsent.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("identificationPhoto.cancel", action: cancel)
                        .accessibilityIdentifier("cancelExternalAIConsent")
                }
            }
        }.tint(Color("PrimaryAction"))
        .accessibilityIdentifier("externalAIConsentSheet")
    }
}
