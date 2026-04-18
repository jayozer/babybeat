import SwiftUI

struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section(
                    title: "How kick counting works",
                    body: "In the third trimester, tracking fetal movement patterns can help you notice changes worth raising with your healthcare provider. The typical guidance is to count movements until you reach 10 — most parents will in under an hour."
                )

                section(
                    title: "Using Baby Kick Count",
                    body: "Tap the heart whenever you feel a movement. The timer starts at the first tap and runs for up to 2 hours. Pause, undo, or end anytime. Your data stays on your device."
                )

                section(
                    title: "Important",
                    body: "This app is for educational purposes only — it is not a medical device and does not diagnose conditions. Contact your healthcare provider if movements change abruptly, slow down, or stop; if you cannot feel 10 movements in 2 hours; or if you have any concerns."
                )
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Information")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .softCard()
    }
}
