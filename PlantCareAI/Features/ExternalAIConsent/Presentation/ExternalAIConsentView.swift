import SwiftUI

struct ExternalAIConsentView: View {
    var usesRealRecipient = false
    var destination: ExternalAIDestinationNotice?
    var analyzingPhoto = false
    let accept: () -> Void
    let cancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(usesRealRecipient ? "analysis.consentBody" : "externalAIConsent.body").accessibilityIdentifier("externalAIConsentBody")
                    if analyzingPhoto { Text("analysis.consentOperation").font(.callout) }
                    if usesRealRecipient, let destination {
                        Text("identifyCandidates.destination").font(.headline)
                        Text(verbatim: destination.destination)
                            .multilineTextAlignment(.leading)
                            .accessibilityIdentifier("externalAIActualDestination")
                        Text("identifyCandidates.model").font(.headline)
                        Text(verbatim: destination.model).accessibilityIdentifier("externalAIActualModel")
                        Text("identifyCandidates.unknownOperator").font(.callout)
                            .accessibilityIdentifier("externalAIUnknownOperator")
                    }
                    Text(usesRealRecipient ? "identifyCandidates.cancellationLimit" : "externalAIConsent.notAvailable").font(.callout)
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
