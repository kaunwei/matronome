import Foundation

/// PracticeStats provides analytical metrics across daily, weekly, and custom ranges.
public struct PracticeStats: Sendable {
    public struct DaySummary: Identifiable, Sendable, Equatable {
        public var id: Date { date }
        public let date: Date
        public let totalDuration: TimeInterval
        public let sessionCount: Int
        public let averageTempo: Double

        public init(date: Date, totalDuration: TimeInterval, sessionCount: Int, averageTempo: Double) {
            self.date = date
            self.totalDuration = totalDuration
            self.sessionCount = sessionCount
            self.averageTempo = averageTempo
        }
    }

    public let sessions: [PracticeSession]
    public let calendar: Calendar

    public init(sessions: [PracticeSession], calendar: Calendar = .current) {
        self.sessions = sessions
        self.calendar = calendar
    }

    /// Total practice time across all sessions.
    public var totalTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    /// Total number of sessions completed.
    public var totalSessionsCount: Int {
        sessions.count
    }

    /// Average session duration in seconds.
    public var averageSessionDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return totalTime / Double(sessions.count)
    }

    /// Average tempo across all sessions (weighted by session duration).
    public var weightedAverageTempo: Double {
        let total = totalTime
        guard total > 0 else {
            return sessions.isEmpty ? 0 : sessions.reduce(0.0) { $0 + $1.tempo } / Double(sessions.count)
        }
        let weightedSum = sessions.reduce(0.0) { $0 + ($1.tempo * $1.duration) }
        return weightedSum / total
    }

    /// Practice duration accumulated on a specific date (calendar day).
    public func practiceTime(on date: Date) -> TimeInterval {
        sessions(on: date).reduce(0) { $0 + $1.duration }
    }

    /// Sessions recorded on a specific date (calendar day).
    public func sessions(on date: Date) -> [PracticeSession] {
        sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    /// Practice time accumulated within the calendar week containing the given date.
    public func weeklyPracticeTime(for date: Date = Date()) -> TimeInterval {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return 0
        }
        return sessions.filter { weekInterval.contains($0.date) }.reduce(0) { $0 + $1.duration }
    }

    /// Aggregates daily practice summaries for the last N days leading up to referenceDate.
    public func dailySummaries(lastDays days: Int, endingAt referenceDate: Date = Date()) -> [DaySummary] {
        guard days > 0 else { return [] }
        var result: [DaySummary] = []

        let startOfRefDay = calendar.startOfDay(for: referenceDate)

        for dayOffset in stride(from: days - 1, through: 0, by: -1) {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfRefDay) else {
                continue
            }
            let matchingSessions = sessions(on: targetDate)
            let duration = matchingSessions.reduce(0.0) { $0 + $1.duration }
            let count = matchingSessions.count
            let avgTempo = count > 0 ? matchingSessions.reduce(0.0) { $0 + $1.tempo } / Double(count) : 0.0

            result.append(DaySummary(
                date: targetDate,
                totalDuration: duration,
                sessionCount: count,
                averageTempo: avgTempo
            ))
        }

        return result
    }

    /// Calculates consecutive practice streak in days ending today or yesterday.
    public func currentStreak(asOf referenceDate: Date = Date()) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let startOfRefDay = calendar.startOfDay(for: referenceDate)
        var checkDate = startOfRefDay

        // If today has no sessions, check if streak is active through yesterday
        if practiceTime(on: checkDate) == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate),
                  practiceTime(on: yesterday) > 0 else {
                return 0
            }
            checkDate = yesterday
        }

        var streak = 0
        while practiceTime(on: checkDate) > 0 {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return streak
    }
}
