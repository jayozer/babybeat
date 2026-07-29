import SwiftUI

struct CalendarGridView: View {
    let sessions: [KickSession]
    @Binding var selectedDate: Date

    @State private var displayedMonth: Date

    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1 // Sunday, to match the weekday header below
        return c
    }()
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    init(sessions: [KickSession], selectedDate: Binding<Date>) {
        self.sessions = sessions
        self._selectedDate = selectedDate
        self._displayedMonth = State(initialValue: Calendar.current.startOfMonth(for: selectedDate.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(Theme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }

                ForEach(0..<leadingPadCount, id: \.self) { _ in
                    Color.clear.frame(height: 40)
                }

                ForEach(monthDays, id: \.self) { day in
                    DayCell(
                        date: day,
                        isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(day),
                        markers: markers(for: day)
                    )
                    .onTapGesture { selectedDate = day }
                }
            }
            // Seven fixed columns can't reflow, so past a point extra text
            // growth only wraps "10" into "1"/"0". Cap the grid and let the
            // glyphs shrink to fit instead. The header, legend and month
            // controls outside this grid still scale the whole way.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)

            legend
        }
        .padding(16)
        .softCard()
    }

    private var header: some View {
        HStack {
            Button(action: { shift(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.inkMuted)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            Spacer()
            Text(monthTitle)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button(action: { shift(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.inkMuted)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }

    private var legend: some View {
        // Three labels side by side stop fitting at accessibility sizes, where
        // they hyphenate into "Com-/plete". Stack them instead of shrinking, so
        // the legend keeps scaling the whole way.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { legendItems }
            VStack(alignment: .leading, spacing: 6) { legendItems }
        }
        .font(.caption2)
        .foregroundStyle(Theme.inkFaint)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var legendItems: some View {
        legendDot(color: Theme.primaryLight, label: "Complete")
        legendDot(color: Theme.timeoutAmber, label: "Timeout")
        legendDot(color: Theme.endedLavender, label: "Ended")
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).lineLimit(1)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var leadingPadCount: Int {
        let first = calendar.startOfMonth(for: displayedMonth)
        let weekday = calendar.component(.weekday, from: first)
        // Modulo 7 so the offset stays in 0..<7 regardless of firstWeekday.
        return ((weekday - calendar.firstWeekday) % 7 + 7) % 7
    }

    private var monthDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let start = calendar.startOfMonth(for: displayedMonth)
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: start)
        }
    }

    private func shift(by months: Int) {
        if let shifted = calendar.date(byAdding: .month, value: months, to: displayedMonth) {
            displayedMonth = calendar.startOfMonth(for: shifted)
        }
    }

    private func markers(for day: Date) -> [Color] {
        let matches = sessions.filter {
            guard let started = $0.startedAt else { return false }
            return calendar.isDate(started, inSameDayAs: day)
        }
        var colors: [Color] = []
        if matches.contains(where: { $0.status == .complete }) { colors.append(Theme.primaryLight) }
        if matches.contains(where: { $0.status == .timeout }) { colors.append(Theme.timeoutAmber) }
        if matches.contains(where: { $0.status == .endedEarly }) { colors.append(Theme.endedLavender) }
        return colors
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let markers: [Color]

    var body: some View {
        VStack(spacing: 2) {
            Text(dayString)
                .font(.system(.callout, design: .rounded).weight(isSelected ? .bold : .regular))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            HStack(spacing: 2) {
                ForEach(markers.indices, id: \.self) { idx in
                    Circle()
                        .fill(isSelected ? Color.white : markers[idx])
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private var accessibilityText: String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        var text = f.string(from: date)
        if isToday { text += ", today" }
        if isSelected { text += ", selected" }
        if markers.isEmpty {
            text += ", no sessions"
        } else if markers.count == 1 {
            text += ", 1 session recorded"
        } else {
            text += ", \(markers.count) sessions recorded"
        }
        return text
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            Theme.primary
        } else if isToday {
            Theme.divider
        } else {
            Color.clear
        }
    }

    private var foreground: Color {
        if isSelected { return .white }
        if isToday { return Theme.primaryDark }
        return Theme.inkMuted
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: self.dateComponents([.year, .month], from: date)) ?? date
    }
}
