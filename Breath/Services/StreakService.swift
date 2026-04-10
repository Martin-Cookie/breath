import Foundation

/// Spočítá streak na základě dat dokončených session.
/// Streak = po sobě jdoucí kalendářní dny s alespoň jednou session.
enum StreakService {

    struct StreakInfo: Equatable {
        let currentStreak: Int
        let bestStreak: Int
        let lastSessionDate: Date?
    }

    /// Spočítá streak info z kolekce sessions (vstup nemusí být seřazený).
    static func compute(
        from sessions: [Session],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) -> StreakInfo {
        guard !sessions.isEmpty else {
            return StreakInfo(currentStreak: 0, bestStreak: 0, lastSessionDate: nil)
        }

        let uniqueDays: [Date] = Array(Set(sessions.map { calendar.startOfDay(for: $0.date) }))
            .sorted(by: >)

        let today = calendar.startOfDay(for: referenceDate)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        var current = 0
        if let mostRecent = uniqueDays.first, mostRecent == today || mostRecent == yesterday {
            current = 1
            var cursor = mostRecent
            for day in uniqueDays.dropFirst() {
                guard let expected = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                if day == expected {
                    current += 1
                    cursor = day
                } else {
                    break
                }
            }
        }

        // Nejdelší streak napříč celou historií
        var best = 0
        var run = 0
        var previous: Date?
        for day in uniqueDays.reversed() {
            if let prev = previous, let expected = calendar.date(byAdding: .day, value: 1, to: prev), expected == day {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }

        return StreakInfo(
            currentStreak: current,
            bestStreak: best,
            lastSessionDate: uniqueDays.first
        )
    }
}
