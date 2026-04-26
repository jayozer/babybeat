import SwiftUI

struct SessionSummarySheet: View {
    let session: KickSession
    let onStartNew: () -> Void
    let onSave: (_ rating: Int?, _ notes: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int?
    @State private var notes: String = ""

    init(session: KickSession, onSave: @escaping (Int?, String) -> Void, onStartNew: @escaping () -> Void) {
        self.session = session
        self.onSave = onSave
        self.onStartNew = onStartNew
        _rating = State(initialValue: session.strengthRating)
        _notes = State(initialValue: session.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    headline
                    stats
                }

                Section {
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                rating = (rating == value) ? nil : value
                            } label: {
                                Image(systemName: rating.map { value <= $0 } ?? false ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundStyle(Theme.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("How strong were the movements?")
                }

                Section {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }

                Section {
                    Button {
                        onSave(rating, notes)
                        onStartNew()
                        dismiss()
                    } label: {
                        Text("Start New Session")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .tint(Theme.primary)
                }
            }
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(rating, notes)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var headline: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title)
                .foregroundStyle(iconColor)
            VStack(alignment: .leading) {
                Text(title).font(.headline).foregroundStyle(Theme.ink)
                Text(subtitle).font(.caption).foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var stats: some View {
        HStack {
            stat(label: "Kicks", value: "\(session.kickCount)")
            Divider()
            stat(label: "Duration", value: durationString)
            Divider()
            stat(label: "Target", value: "\(session.targetCount)")
        }
        .padding(.vertical, 4)
    }

    private func stat(label: String, value: String) -> some View {
        VStack {
            Text(value).font(.title3.weight(.semibold)).foregroundStyle(Theme.primaryDark)
            Text(label).font(.caption).foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
    }

    private var durationString: String {
        let total = Int(session.durationSec ?? 0)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private var title: String {
        switch session.status {
        case .complete: return "Target reached"
        case .timeout: return "Time's up"
        case .endedEarly: return "Session ended"
        default: return "Session summary"
        }
    }

    private var subtitle: String {
        switch session.status {
        case .complete: return "You counted \(session.kickCount) movements."
        case .timeout: return "Reached the 2-hour limit."
        case .endedEarly: return "Ended before reaching target."
        default: return ""
        }
    }

    private var iconName: String {
        switch session.status {
        case .complete: return "checkmark.circle.fill"
        case .timeout: return "clock.fill"
        case .endedEarly: return "stop.circle.fill"
        default: return "heart"
        }
    }

    private var iconColor: Color {
        switch session.status {
        case .complete: return Theme.primary
        case .timeout: return Theme.timeoutAmber
        case .endedEarly: return Theme.endedLavender
        default: return Theme.inkMuted
        }
    }
}
