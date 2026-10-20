import Foundation

/// PracticeTargetTimer manages a target countdown duration and fires a callback upon completion.
/// Time tracking is driven purely by monotonic wall-clock time, fully decoupled from audio playback rate or subdivision intervals.
public final class PracticeTargetTimer: @unchecked Sendable {
    private let lock = NSLock()
    
    private var targetDurationInternal: TimeInterval
    private var remainingTimeInternal: TimeInterval
    private var isRunningInternal: Bool = false
    private var lastTickTime: TimeInterval?
    private let timeProvider: @Sendable () -> TimeInterval
    
    public var onTargetReached: (@Sendable () -> Void)?
    public var onTick: (@Sendable (TimeInterval) -> Void)?

    public init(
        targetDuration: TimeInterval = 0,
        timeProvider: @escaping @Sendable () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        let safeDuration = max(0, targetDuration)
        self.targetDurationInternal = safeDuration
        self.remainingTimeInternal = safeDuration
        self.timeProvider = timeProvider
    }

    /// Target countdown duration in seconds.
    public var targetDuration: TimeInterval {
        get {
            lock.lock()
            defer { lock.unlock() }
            return targetDurationInternal
        }
        set {
            setTargetDuration(newValue)
        }
    }

    /// Sets a new target duration and resets remaining time.
    public func setTargetDuration(_ duration: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        let safeDuration = max(0, duration)
        self.targetDurationInternal = safeDuration
        self.remainingTimeInternal = safeDuration
        self.lastTickTime = isRunningInternal ? timeProvider() : nil
    }

    /// Starts or resumes the target timer countdown.
    public func start() {
        lock.lock()
        defer { lock.unlock() }
        guard !isRunningInternal, remainingTimeInternal > 0 else { return }
        isRunningInternal = true
        lastTickTime = timeProvider()
    }

    /// Pauses the countdown, committing elapsed monotonic time.
    public func pause() {
        lock.lock()
        defer { lock.unlock() }
        guard isRunningInternal else { return }
        let now = timeProvider()
        if let last = lastTickTime {
            let elapsed = max(0, now - last)
            remainingTimeInternal = max(0, remainingTimeInternal - elapsed)
        }
        isRunningInternal = false
        lastTickTime = nil
    }

    /// Stops and resets the countdown to target duration.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        isRunningInternal = false
        remainingTimeInternal = targetDurationInternal
        lastTickTime = nil
    }

    /// Advances the timer manually by a specified delta time (seconds), triggering callbacks when reached.
    public func advance(by delta: TimeInterval) {
        var didReachTarget = false
        var targetCallback: (@Sendable () -> Void)?
        var tickCallback: (@Sendable (TimeInterval) -> Void)?
        var currentRemaining: TimeInterval = 0

        lock.lock()
        guard isRunningInternal else {
            lock.unlock()
            return
        }

        // Align lastTickTime to current monotonic time so subsequent tick/read doesn't double-count elapsed time
        if lastTickTime != nil {
            lastTickTime = timeProvider()
        }

        remainingTimeInternal = max(0, remainingTimeInternal - delta)
        currentRemaining = remainingTimeInternal

        if remainingTimeInternal <= 0 {
            isRunningInternal = false
            lastTickTime = nil
            didReachTarget = true
            targetCallback = onTargetReached
        }
        tickCallback = onTick
        lock.unlock()

        tickCallback?(currentRemaining)
        if didReachTarget {
            targetCallback?()
        }
    }

    /// Ticks the timer based on monotonic wall-clock elapsed time since last tick.
    public func tick() {
        var didReachTarget = false
        var targetCallback: (@Sendable () -> Void)?
        var tickCallback: (@Sendable (TimeInterval) -> Void)?
        var currentRemaining: TimeInterval = 0

        lock.lock()
        guard isRunningInternal, let last = lastTickTime else {
            lock.unlock()
            return
        }
        let now = timeProvider()
        let elapsed = max(0, now - last)
        lastTickTime = now
        remainingTimeInternal = max(0, remainingTimeInternal - elapsed)
        currentRemaining = remainingTimeInternal

        if remainingTimeInternal <= 0 {
            isRunningInternal = false
            lastTickTime = nil
            didReachTarget = true
            targetCallback = onTargetReached
        }
        tickCallback = onTick
        lock.unlock()

        tickCallback?(currentRemaining)
        if didReachTarget {
            targetCallback?()
        }
    }

    /// Internal helper calculating current remaining time without mutating state.
    private func currentRemainingLocked(at now: TimeInterval? = nil) -> TimeInterval {
        guard isRunningInternal, let last = lastTickTime else {
            return remainingTimeInternal
        }
        let currentTime = now ?? timeProvider()
        let elapsed = max(0, currentTime - last)
        return max(0, remainingTimeInternal - elapsed)
    }

    /// Remaining countdown time in seconds, computed accurately against monotonic wall-clock time.
    public var remainingTime: TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return currentRemainingLocked()
    }

    /// Whether the timer is currently running.
    public var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isRunningInternal
    }

    /// Progress from 0.0 (just started) to 1.0 (completed), consistent with remainingTime.
    public var progress: Double {
        lock.lock()
        defer { lock.unlock() }
        guard targetDurationInternal > 0 else { return 1.0 }
        let remaining = currentRemainingLocked()
        return min(1.0, max(0.0, (targetDurationInternal - remaining) / targetDurationInternal))
    }

    /// Whether the target duration has elapsed, consistent with remainingTime.
    public var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return targetDurationInternal > 0 && currentRemainingLocked() <= 0
    }
}
