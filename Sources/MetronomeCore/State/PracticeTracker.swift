import Foundation

/// Represents a single practice session record.
public struct PracticeSession: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let duration: TimeInterval
    public let tempo: Double
    public let notes: String?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        tempo: Double = 120.0,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.tempo = tempo
        self.notes = notes
    }
}

/// Thread-safe practice time tracker that manages current session duration,
/// persistent total practice time across sessions, and session history records.
public final class PracticeTracker: @unchecked Sendable {
    private let lock = NSLock()
    private let userDefaults: UserDefaults?
    private let totalTimeStorageKey: String
    private let sessionsStorageKey: String

    private var sessionStartTime: Date?
    private var accumulatedSessionTime: TimeInterval = 0
    private var isRunningInternal: Bool = false
    private var persistedTotalPracticeTime: TimeInterval = 0
    private var sessions: [PracticeSession] = []

    public init(
        userDefaults: UserDefaults? = .standard,
        totalTimeKey: String = "Metronome_TotalPracticeTime",
        sessionsKey: String = "Metronome_PracticeSessions"
    ) {
        self.userDefaults = userDefaults
        self.totalTimeStorageKey = totalTimeKey
        self.sessionsStorageKey = sessionsKey

        loadPersistedData()
    }

    /// Loads persisted total practice time and session history.
    private func loadPersistedData() {
        guard let defaults = userDefaults else { return }
        self.persistedTotalPracticeTime = defaults.double(forKey: totalTimeStorageKey)

        if let data = defaults.data(forKey: sessionsStorageKey),
           let decoded = try? JSONDecoder().decode([PracticeSession].self, from: data) {
            self.sessions = decoded
        }
    }

    /// Saves persisted state to UserDefaults.
    private func savePersistedData() {
        guard let defaults = userDefaults else { return }
        defaults.set(persistedTotalPracticeTime, forKey: totalTimeStorageKey)

        if let data = try? JSONEncoder().encode(sessions) {
            defaults.set(data, forKey: sessionsStorageKey)
        }
    }

    /// Whether a practice session is currently running.
    public var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isRunningInternal
    }

    /// Starts or resumes practice time tracking.
    public func start() {
        lock.lock()
        defer { lock.unlock() }
        guard !isRunningInternal else { return }
        isRunningInternal = true
        sessionStartTime = Date()
    }

    /// Pauses practice time tracking.
    public func pause() {
        lock.lock()
        defer { lock.unlock() }
        guard isRunningInternal else { return }
        if let startTime = sessionStartTime {
            accumulatedSessionTime += Date().timeIntervalSince(startTime)
            sessionStartTime = nil
        }
        isRunningInternal = false
    }

    /// Stops practice tracking, logs the completed session, and accumulates total practice time.
    /// Returns the completed session if one was active and recorded.
    @discardableResult
    public func stop(tempo: Double = 120.0, notes: String? = nil) -> PracticeSession? {
        lock.lock()
        defer { lock.unlock() }

        var finalDuration = accumulatedSessionTime
        if isRunningInternal, let startTime = sessionStartTime {
            finalDuration += Date().timeIntervalSince(startTime)
        }

        isRunningInternal = false
        sessionStartTime = nil
        accumulatedSessionTime = 0

        guard finalDuration > 0 else { return nil }

        persistedTotalPracticeTime += finalDuration

        let session = PracticeSession(
            date: Date(),
            duration: finalDuration,
            tempo: tempo,
            notes: notes
        )
        sessions.append(session)
        savePersistedData()

        return session
    }

    /// Resets current session practice time without adding to persistent total.
    public func resetCurrentSession() {
        lock.lock()
        defer { lock.unlock() }
        sessionStartTime = isRunningInternal ? Date() : nil
        accumulatedSessionTime = 0
    }

    /// Resets all history and persistent total practice time.
    public func resetAll() {
        lock.lock()
        defer { lock.unlock() }
        sessionStartTime = isRunningInternal ? Date() : nil
        accumulatedSessionTime = 0
        persistedTotalPracticeTime = 0
        sessions.removeAll()
        savePersistedData()
    }

    /// Elapsed time for the current practice session in seconds.
    public var currentPracticeTime: TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        var current = accumulatedSessionTime
        if isRunningInternal, let startTime = sessionStartTime {
            current += Date().timeIntervalSince(startTime)
        }
        return current
    }

    /// Total accumulated practice time across all recorded sessions in seconds.
    public var totalPracticeTime: TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return persistedTotalPracticeTime
    }

    /// Total accumulated practice time including the active session in progress.
    public var totalPracticeTimeWithCurrentSession: TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        var current = accumulatedSessionTime
        if isRunningInternal, let startTime = sessionStartTime {
            current += Date().timeIntervalSince(startTime)
        }
        return persistedTotalPracticeTime + current
    }

    /// All recorded practice sessions.
    public var sessionHistory: [PracticeSession] {
        lock.lock()
        defer { lock.unlock() }
        return sessions
    }

    /// Manually injects or records a session (useful for test mocks and sync).
    public func addSession(_ session: PracticeSession) {
        lock.lock()
        defer { lock.unlock() }
        sessions.append(session)
        persistedTotalPracticeTime += session.duration
        savePersistedData()
    }
}
