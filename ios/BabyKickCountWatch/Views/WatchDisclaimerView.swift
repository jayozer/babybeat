import SwiftUI

/// First-launch acknowledgement of the shared medical disclaimer. Uses the
/// same load-bearing wording as the iPhone's onboarding and info screens.
struct WatchDisclaimerView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(MedicalDisclaimer.onboardingTitle)
                    .font(.headline)
                    .foregroundStyle(Theme.primary)

                Text(MedicalDisclaimer.body)
                    .font(.footnote)

                Button("I Understand", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Littletaps")
    }
}
