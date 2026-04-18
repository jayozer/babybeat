import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var pageIndex = 0

    private let pages: [Page] = [
        Page(
            icon: "heart.fill",
            title: "Welcome to Baby Kick Count",
            body: "A calm, simple way to track your baby's movements during the third trimester."
        ),
        Page(
            icon: "hand.tap.fill",
            title: "One tap at a time",
            body: "Tap the heart whenever you feel a movement. We'll track the time and count to 10 for you."
        ),
        Page(
            icon: "clock.fill",
            title: "2-hour session",
            body: "Each session runs up to 2 hours. Pause or end anytime. Your data stays on this device."
        )
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                TabView(selection: $pageIndex) {
                    ForEach(pages.indices, id: \.self) { idx in
                        PageView(page: pages[idx]).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxHeight: .infinity)

                Button {
                    if pageIndex < pages.count - 1 {
                        withAnimation { pageIndex += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(pageIndex < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.primary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private struct PageView: View {
        let page: Page

        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 60)
                Text(page.title)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
        }
    }
}
