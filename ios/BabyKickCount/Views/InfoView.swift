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
                    title: "Using Littletaps",
                    body: "Tap the heart whenever you feel a movement. The timer starts at the first tap and runs for up to 2 hours. Pause, undo, or end anytime. Your data stays on your device."
                )

                section(
                    title: "Important",
                    body: "This app is for educational purposes only — it is not a medical device and does not diagnose conditions. Contact your healthcare provider if movements change abruptly, slow down, or stop; if you cannot feel 10 movements in 2 hours; or if you have any concerns."
                )

                linkSection
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

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Privacy & support")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 10)

            linkRow(
                title: "Privacy Policy",
                subtitle: "How local app data and CSV exports work",
                systemImage: "lock.shield",
                destination: AppURLs.privacy
            )

            Divider().padding(.leading, 34)

            linkRow(
                title: "Terms of Use",
                subtitle: "Important medical disclaimer and use terms",
                systemImage: "doc.text",
                destination: AppURLs.terms
            )

            Divider().padding(.leading, 34)

            linkRow(
                title: "Support",
                subtitle: "Troubleshooting and contact information",
                systemImage: "lifepreserver",
                destination: AppURLs.support
            )

            Divider().padding(.leading, 34)

            linkRow(
                title: "Email Support",
                subtitle: "hello@babykickcount.com",
                systemImage: "envelope",
                destination: AppURLs.supportEmail
            )
        }
        .padding(16)
        .softCard()
    }

    private func linkRow(title: String, subtitle: String, systemImage: String, destination: URL) -> some View {
        Link(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.inkFaint)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 10)
        }
        .accessibilityHint("Opens outside the app")
    }
}
