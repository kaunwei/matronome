import Foundation

/// PracticeTargetTimer manages a target countdown duration and fires a callback upon completion.
public final class PracticeTargetTimer: @unchecked Sendable {
    private let lock = NSLock()
    
    public var targetDuration: TimeInterval
    private var remainingTimeInternal: TimeInterval
    private var isRunningInternal: Bool = false
    private var lastTickTime: Date?
    
    public var onTargetReached: (@Sendable () -> Void)?
    public var onTick: (@Sendable (TimeInterval) -> Void)?

    public init(targetDuration: TimeInterval = 0) {
        self.targetDuration = max(0, targetDuration)
        self.remainingTimeInternal = max(0, targetDuration)
    }

    /// Sets a new target duration and resets remaining time.
    public func setTargetDuration(_ duration: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        self.targetDuration = max(0, duration)
        self.remainingTimeInternal = max(0, duration)
        self.lastTickTime = isRunningInternal ? Date() : nil
    }

    /// Starts or resumes the target timer countdown.
    public func start() {
        lock.lock()
        defer { lock.unlock() }
        guard !isRunningInternal, remainingTimeInternal > 0 else { return }
        isRunningInternal = true
        lastTickTime = Date()
    }

    /// Pauses the countdown.
    public func pause() {
        lock.lock()
        defer { lock.unlock() }
        updateRemainingTimeLocked()
        isRunningInternal = false
        lastTickTime = nil
    }

    /// Stops and resets the countdown to target duration.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        isRunningInternal = false
        remainingTimeInternal = targetDuration
        lastTickTime = nil
    }

    /// Advances the timer by a specified delta time (seconds), triggering callbacks when reached.
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

    /// Ticks the timer based on wall-clock elapsed time since last tick.
    public func tick() {
        var delta: TimeInterval = 0
        lock.lock()
        guard isRunningInternal, let last = lastTickTime else {
            lock.unlock()
            return
        }
        let now = Date()
        delta = now.timeIntervalSince(last)
        lastTickTime = now
        lock.unlock()

        if delta > 0 {
            advance(by: delta)
        }
    }

    /// Internal helper to update remaining time while holding lock.
    private func updateRemainingTimeLocked() {
        guard isRunningInternal, let last = lastTickTime else { return }
        let now = Date()
        let delta = now.timeIntervalSince(last)
        remainingTimeInternal = max(0, remainingTimeInternal - delta)
        lastTickTime = now
    }

    /// Remaining countdown time in seconds.
    public var remainingTime: TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        if isRunningInternal, let last = lastTickTime {
            let delta = Date().timeIntervalSince(last)
            return max(0, remainingTimeInternal - delta)
        }
        return remainingTimeInternal
    }

    /// Whether the timer is currently running.
    public var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isRunningInternal
    }

    /// Progress from 0.0 (just started) to 1.0 (completed).
    public var progress: Double {
        lock.lock()
        defer { lock.unlock() }
        guard targetDuration > 0 else { return 1.0 }
        let remaining = remainingTimeInternal
        return min(1.0, max(0.0, (targetDuration - remaining) / targetDuration))
    }

    /// Whether the target duration has elapsed.
    public var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return targetDuration > 0 && remainingTimeInternal <= 0
    }
}
