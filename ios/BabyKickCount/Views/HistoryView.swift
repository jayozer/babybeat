import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KickSession.createdAt, order: .reverse) private var sessions: [KickSession]

    @State private var selectedDate: Date = .now

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    CalendarGridView(sessions: sessions, selectedDate: $selectedDate)

                    sessionList
                }
                .padding(16)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredSessions: [KickSession] {
        sessions.filter { session in
            guard let started = session.startedAt else { return false }
            return calendar.isDate(started, inSameDayAs: selectedDate)
        }
    }

    @ViewBuilder
    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(headerTitle)
                .font(.headline)
                .foregroundStyle(Theme.ink)

            if filteredSessions.isEmpty {
                Text("No sessions recorded this day.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(filteredSessions) { session in
                    SessionRow(session: session, onDelete: { delete(session) })
                }
            }
        }
        .padding(16)
        .softCard()
    }

    private var headerTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: selectedDate)
    }

    private func delete(_ session: KickSession) {
        context.delete(session)
        try? context.save()
    }
}

private struct SessionRow: View {
    let session: KickSession
    let onDelete: () -> Void

    @State private var confirmingDelete = false

    var body: some View {
        HStack(spacing: 12) {
            statusIndicator
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                Text(subtitle).font(.caption).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            Menu {
                Button(role: .destructive) { confirmingDelete = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis").foregroundStyle(Theme.inkMuted).padding(8)
            }
        }
        .padding(.vertical, 6)
        .confirmationDialog("Delete session?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }

    private var statusIndicator: some View {
        Circle().fill(color).frame(width: 10, height: 10)
    }

    private var color: Color {
        switch session.status {
        case .complete: return Theme.primaryLight
        case .timeout: return Theme.timeoutAmber
        case .endedEarly: return Theme.endedLavender
        default: return Theme.inkFaint
        }
    }

    private var title: String {
        let countLabel = "\(session.kickCount) of \(session.targetCount) kicks"
        return "\(countLabel) — \(session.status.displayName)"
    }

    private var subtitle: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        let start = session.startedAt.map { f.string(from: $0) } ?? "—"
        let duration = session.durationSec.map { formatDuration($0) } ?? "—"
        return "Started \(start) · \(duration)"
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
