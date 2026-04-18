import SwiftUI

struct CalendarGridView: View {
    let sessions: [KickSession]
    @Binding var selectedDate: Date

    @State private var displayedMonth: Date

    private let calendar = Calendar.current
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
                    .padding(8)
            }
            Spacer()
            Text(monthTitle)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button(action: { shift(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.inkMuted)
                    .padding(8)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendDot(color: Theme.primaryLight, label: "Complete")
            legendDot(color: Theme.timeoutAmber, label: "Timeout")
            legendDot(color: Theme.endedLavender, label: "Ended")
        }
        .font(.caption2)
        .foregroundStyle(Theme.inkFaint)
        .padding(.top, 4)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
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
        return weekday - calendar.firstWeekday // 0-based
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

            HStack(spacing: 2) {
                ForEach(markers.indices, id: \.self) { idx in
                    Circle()
                        .fill(isSelected ? Color.white : markers[idx])
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
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
