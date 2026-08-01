import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct KickSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KickSessionAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color.white.opacity(0.75))
                .activitySystemActionForegroundColor(Theme.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    CountBadge(count: context.state.kickCount, target: context.state.targetCount)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Countdown(state: context.state)
                            .font(.system(.title3, design: .monospaced).weight(.medium))
                        Text(context.state.isPaused ? "paused" : "left in your window")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Runs in the app's process, so a movement can be recorded
                    // straight from the Lock Screen without unlocking.
                    Button(intent: LogTapIntent()) {
                        Label("Log a tap", systemImage: "heart.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .tint(Theme.primary)
                    .disabled(context.state.isPaused)
                }
            } compactLeading: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.primary)
            } compactTrailing: {
                Text("\(context.state.kickCount)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.primary)
            } minimal: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.primary)
            }
            .keylineTint(Theme.primary)
        }
    }
}

private struct LockScreenView: View {
    let state: KickSessionAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            CountBadge(count: state.kickCount, target: state.targetCount)

            VStack(alignment: .leading, spacing: 6) {
                Text("Littletaps")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Countdown(state: state)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.inkMuted)

                ProgressView(value: state.progress)
                    .tint(Theme.primary)
            }

            Button(intent: LogTapIntent()) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .tint(Theme.primary)
            .disabled(state.isPaused)
            .accessibilityLabel("Log a tap")
        }
        .padding(16)
    }
}

private struct CountBadge: View {
    let count: Int
    let target: Int

    var body: some View {
        ZStack {
            Circle().fill(Theme.tapPadGradient)
            VStack(spacing: -2) {
                Text("\(count)")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Text("of \(target)")
                    .font(.system(size: 10, design: .rounded))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
        }
        .frame(width: 56, height: 56)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) of \(target) movements")
    }
}

/// The system animates this with nothing of ours alive, which is why the app
/// never has to push a per-second update.
private struct Countdown: View {
    let state: KickSessionAttributes.ContentState

    var body: some View {
        if state.isPaused {
            Text("Paused")
        } else {
            Text(timerInterval: Date.now...max(state.windowEnd, Date.now.addingTimeInterval(1)),
                 countsDown: true)
        }
    }
}
