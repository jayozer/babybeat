import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.modelContext) private var context
    @Query(sort: \KickSession.createdAt, order: .reverse) private var sessions: [KickSession]

    @State private var showExporter = false
    @State private var exportText: String = ""
    @State private var exportFilename: String = "kick-count.csv"

    var body: some View {
        Form {
            Section {
                ForEach(SoundOption.allCases) { option in
                    soundRow(option)
                }
            } header: {
                Text("Tap Sound")
            } footer: {
                Text("Select the sound played when you tap")
            }

            Section {
                Toggle("Vibration", isOn: vibrationBinding)
                    .tint(Theme.primary)
            } header: {
                Text("Haptic Feedback")
            } footer: {
                Text("Haptic feedback on tap")
            }

            Section {
                Toggle("Keep Screen Awake", isOn: keepAwakeBinding)
                    .tint(Theme.primary)
            } header: {
                Text("Screen")
            } footer: {
                Text("Prevent screen from sleeping during a session")
            }

            Section {
                Button("Summary Export") { triggerExport(kind: .summary) }
                Button("Detailed Export") { triggerExport(kind: .detailed) }
            } header: {
                Text("Data")
            } footer: {
                Text("\(ExportService.exportableCount(sessions: sessions)) completed sessions available. Summary: one row per session. Detailed: individual kick timestamps.")
            }

            Section {
                LabeledContent("Version", value: appVersion)
                NavigationLink("Information & Help") { InfoView() }
                Link("Privacy Policy", destination: AppURLs.privacy)
                Link("Terms of Use", destination: AppURLs.terms)
                Link("Support", destination: AppURLs.support)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExporter) {
            ShareSheet(text: exportText, filename: exportFilename)
        }
    }

    private var vibrationBinding: Binding<Bool> {
        Binding(
            get: { preferences.preferences.vibrationEnabled },
            set: { newValue in preferences.update { $0.vibrationEnabled = newValue } }
        )
    }

    private var keepAwakeBinding: Binding<Bool> {
        Binding(
            get: { preferences.preferences.keepScreenAwake },
            set: { newValue in preferences.update { $0.keepScreenAwake = newValue } }
        )
    }

    private func soundRow(_ option: SoundOption) -> some View {
        HStack {
            Button {
                preferences.update { $0.soundOption = option }
            } label: {
                HStack {
                    Image(systemName: preferences.preferences.soundOption == option ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(Theme.primary)
                    VStack(alignment: .leading) {
                        Text(option.label).foregroundStyle(Theme.ink)
                        Text(option.desc).font(.caption).foregroundStyle(Theme.inkFaint)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if option != .none {
                Button {
                    FeedbackService.shared.play(option)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(Theme.primary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private enum ExportKind { case summary, detailed }

    private func triggerExport(kind: ExportKind) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: .now)
        switch kind {
        case .summary:
            exportText = ExportService.summaryCSV(sessions: sessions)
            exportFilename = "kick-count-summary-\(today).csv"
        case .detailed:
            exportText = ExportService.detailedCSV(sessions: sessions)
            exportFilename = "kick-count-detailed-\(today).csv"
        }
        showExporter = true
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? text.data(using: .utf8)?.write(to: url)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
