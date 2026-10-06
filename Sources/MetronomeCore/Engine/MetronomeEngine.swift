import Foundation
import AVFAudio

/// High-level state representing the playback condition of the MetronomeEngine.
public enum MetronomePlaybackState: Equatable, Sendable {
    case stopped
    case playing
    case paused
}

/// Real-time tick payload dispatched during metronome playback.
public struct MetronomeTick: Equatable, Sendable {
    public let event: ScheduledRhythmEvent
    public let tempo: Tempo
    public let isMuted: Bool
    public let currentMeasure: Int
    public let completedMeasures: Int
    public let timestamp: TimeInterval

    public init(
        event: ScheduledRhythmEvent,
        tempo: Tempo,
        isMuted: Bool,
        currentMeasure: Int,
        completedMeasures: Int,
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        self.event = event
        self.tempo = tempo
        self.isMuted = isMuted
        self.currentMeasure = currentMeasure
        self.completedMeasures = completedMeasures
        self.timestamp = timestamp
    }
}

/// Unified metronome engine orchestrating audio playback, scheduling, practice tracking, timers, and trainers.
public final class MetronomeEngine: @unchecked Sendable {
    private let lock = NSRecursiveLock()

    // Subsystems
    public let audioEngine: MetronomeAudioEngine
    public let scheduler: RhythmEventScheduler
    public let practiceTracker: PracticeTracker
    public let practiceTargetTimer: PracticeTargetTimer

    // Configurable state
    public var tempo: Tempo {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            if speedTrainer == nil {
                activeTempo = tempo
            }
        }
    }

    public var pattern: MeasurePattern {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            rebuildScheduleIfNeeded()
        }
    }

    public var grooveFeel: GrooveFeel {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            rebuildScheduleIfNeeded()
        }
    }

    public var timbre: Timbre {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            cachedBuffers = audioEngine.createCachedBuffers(timbre: timbre)
        }
    }

    public var isMuted: Bool = false

    // Trainers
    public var speedTrainer: SpeedTrainer? {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            if let st = speedTrainer {
                activeTempo = st.currentTempo
            } else {
                activeTempo = tempo
            }
        }
    }

    public var gapTrainer: GapTrainer?

    // Tap tempo calculator
    private var tapCalculator = TapTempoCalculator()

    // Playback state & dispatch
    public private(set) var state: MetronomePlaybackState = .stopped
    public private(set) var activeTempo: Tempo

    public var onTick: (@Sendable (MetronomeTick) -> Void)?
    public var onPlaybackStateChanged: (@Sendable (MetronomePlaybackState) -> Void)?
    public var onMeasureChanged: (@Sendable (Int) -> Void)?
    public var onTempoChanged: (@Sendable (Tempo) -> Void)?

    // Internal timing & worker loop
    private var timerSource: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.metronome.engine.timer", qos: .userInteractive)

    private var currentMeasureIndex: Int = 0
    private var currentStepInMeasure: Int = 0
    private var totalCompletedMeasures: Int = 0
    private var cachedBuffers: [BeatEmphasis: AVAudioPCMBuffer] = [:]

    public init(
        audioEngine: MetronomeAudioEngine = MetronomeAudioEngine(),
        scheduler: RhythmEventScheduler = RhythmEventScheduler(),
        practiceTracker: PracticeTracker = PracticeTracker(userDefaults: nil),
        practiceTargetTimer: PracticeTargetTimer = PracticeTargetTimer(),
        tempo: Tempo = Tempo(),
        pattern: MeasurePattern = MeasurePattern(),
        grooveFeel: GrooveFeel = .straight,
        timbre: Timbre = .woodblock
    ) {
        self.audioEngine = audioEngine
        self.scheduler = scheduler
        self.practiceTracker = practiceTracker
        self.practiceTargetTimer = practiceTargetTimer
        self.tempo = tempo
        self.activeTempo = tempo
        self.pattern = pattern
        self.grooveFeel = grooveFeel
        self.timbre = timbre

        self.cachedBuffers = audioEngine.createCachedBuffers(timbre: timbre)

        // Setup practice target timer completion callback
        self.practiceTargetTimer.onTargetReached = { [weak self] in
            guard let self = self else { return }
            self.stop()
        }
    }

    deinit {
        stop()
    }

    // MARK: - Playback Control

    /// Starts or resumes playback from current state.
    public func start() throws {
        lock.lock()
        defer { lock.unlock() }

        guard state != .playing else { return }

        try audioEngine.start()
        practiceTracker.start()
        practiceTargetTimer.start()

        state = .playing
        onPlaybackStateChanged?(.playing)

        startTimerLoop()
    }

    /// Pauses playback, preserving measure and step position.
    public func pause() {
        lock.lock()
        defer { lock.unlock() }

        guard state == .playing else { return }

        stopTimerLoop()
        practiceTracker.pause()
        practiceTargetTimer.pause()

        state = .paused
        onPlaybackStateChanged?(.paused)
    }

    /// Stops playback, resets step position, and records session in PracticeTracker.
    public func stop() {
        lock.lock()
        defer { lock.unlock() }

        guard state != .stopped else { return }

        stopTimerLoop()
        practiceTracker.stop(tempo: activeTempo.bpm)
        practiceTargetTimer.reset()
        audioEngine.stop()

        currentMeasureIndex = 0
        currentStepInMeasure = 0
        totalCompletedMeasures = 0

        if var st = speedTrainer {
            st.reset()
            speedTrainer = st
            activeTempo = st.currentTempo
        } else {
            activeTempo = tempo
        }

        if var gt = gapTrainer {
            gt.reset()
            gapTrainer = gt
        }

        state = .stopped
        onPlaybackStateChanged?(.stopped)
    }

    // MARK: - Tap Tempo

    /// Registers a user tap, calculates BPM, and updates tempo live.
    @discardableResult
    public func tapTempo(at timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Tempo? {
        lock.lock()
        defer { lock.unlock() }

        guard let newTempo = tapCalculator.tap(at: timestamp) else {
            return nil
        }

        setTempo(newTempo)
        return newTempo
    }

    /// Resets the tap tempo history.
    public func resetTapTempo() {
        lock.lock()
        defer { lock.unlock() }
        tapCalculator.reset()
    }

    // MARK: - Live Parameter Adjustments

    /// Live tempo adjustment.
    public func setTempo(_ newTempo: Tempo) {
        lock.lock()
        defer { lock.unlock() }

        self.tempo = newTempo
        if speedTrainer == nil {
            let oldTempo = self.activeTempo
            self.activeTempo = newTempo
            if oldTempo != newTempo {
                onTempoChanged?(newTempo)
                if state == .playing {
                    restartTimerLoopCurrentInterval()
                }
            }
        }
    }

    /// Live measure pattern update.
    public func setPattern(_ newPattern: MeasurePattern) {
        lock.lock()
        defer { lock.unlock() }

        self.pattern = newPattern
        if currentStepInMeasure >= newPattern.totalSteps {
            currentStepInMeasure = 0
        }
    }

    /// Live groove feel adjustment.
    public func setGrooveFeel(_ newGrooveFeel: GrooveFeel) {
        lock.lock()
        defer { lock.unlock() }

        self.grooveFeel = newGrooveFeel
    }

    /// Live volume adjustment.
    public func setVolume(_ volume: Float) {
        audioEngine.volume = volume
    }

    /// Live mute toggle.
    public func setMuted(_ muted: Bool) {
        lock.lock()
        defer { lock.unlock() }
        self.isMuted = muted
    }

    // MARK: - Step Execution & Scheduling

    /// Calculates step interval duration for current beat and subdivision step.
    private func currentStepDuration() -> TimeInterval {
        let beatDuration = activeTempo.secondsPerBeat
        let pulsesPerBeat = pattern.subdivision.pulsesPerBeat
        let intervals = scheduler.computeSubdivisionIntervals(
            beatDuration: beatDuration,
            pulsesPerBeat: pulsesPerBeat,
            grooveFeel: grooveFeel
        )
        let subIndex = currentStepInMeasure % pulsesPerBeat
        if subIndex < intervals.count {
            return intervals[subIndex]
        }
        return beatDuration / Double(pulsesPerBeat)
    }

    private func startTimerLoop() {
        stopTimerLoop()

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: timerQueue)
        self.timerSource = timer

        scheduleNextTickOnTimer(timer: timer, delay: 0.0)
        timer.resume()
    }

    private func restartTimerLoopCurrentInterval() {
        guard let timer = timerSource, state == .playing else { return }
        let duration = currentStepDuration()
        timer.schedule(deadline: .now() + duration, leeway: .nanoseconds(100_000))
    }

    private func stopTimerLoop() {
        if let timer = timerSource {
            timer.cancel()
            timerSource = nil
        }
    }

    private func scheduleNextTickOnTimer(timer: DispatchSourceTimer, delay: TimeInterval) {
        let deadline: DispatchTime = delay == 0 ? .now() : .now() + delay
        timer.schedule(deadline: deadline, leeway: .nanoseconds(100_000))
        timer.setEventHandler { [weak self] in
            self?.handleTimerTick()
        }
    }

    /// Executes a single metronome tick, updates state machine, trainer progress, audio playback, and callbacks.
    public func processTick() {
        var tickToDispatch: MetronomeTick?
        var measureCallbackToDispatch: ((Int) -> Void)?
        var newMeasureIndex = 0
        var tempoCallbackToDispatch: ((Tempo) -> Void)?
        var newTempoToNotify: Tempo?
        var stepInterval: TimeInterval = 0

        lock.lock()

        let totalSteps = max(1, pattern.totalSteps)
        let pulsesPerBeat = max(1, pattern.subdivision.pulsesPerBeat)
        let currentStep = currentStepInMeasure
        let beatIndex = currentStep / pulsesPerBeat
        let subIndex = currentStep % pulsesPerBeat
        let emphasis = pattern[currentStep]

        stepInterval = currentStepDuration()

        // Check GapTrainer mute status
        var gapMuted = false
        if let gt = gapTrainer {
            gapMuted = gt.isMuted()
        }

        let shouldMuteAudio = isMuted || gapMuted || (emphasis == .mute)

        // Audio Click Scheduling
        if !shouldMuteAudio && emphasis != .mute {
            if let buffer = cachedBuffers[emphasis] {
                audioEngine.scheduleBuffer(buffer)
            } else {
                audioEngine.scheduleClick(emphasis: emphasis, timbre: timbre)
            }
        }

        let scheduledEvent = ScheduledRhythmEvent(
            measureIndex: currentMeasureIndex,
            beatIndex: beatIndex,
            subdivisionIndex: subIndex,
            stepIndexInMeasure: currentStep,
            emphasis: emphasis,
            timeOffset: 0.0,
            duration: stepInterval
        )

        let tick = MetronomeTick(
            event: scheduledEvent,
            tempo: activeTempo,
            isMuted: shouldMuteAudio,
            currentMeasure: currentMeasureIndex,
            completedMeasures: totalCompletedMeasures
        )
        tickToDispatch = tick

        // Advance step
        currentStepInMeasure += 1
        if currentStepInMeasure >= totalSteps {
            currentStepInMeasure = 0
            currentMeasureIndex += 1
            totalCompletedMeasures += 1
            newMeasureIndex = currentMeasureIndex
            measureCallbackToDispatch = onMeasureChanged

            // Advance GapTrainer
            if var gt = gapTrainer {
                gt.advanceMeasure()
                gapTrainer = gt
            }

            // Advance SpeedTrainer
            if var st = speedTrainer {
                let previousTempo = activeTempo
                let updatedTempo = st.advanceMeasure()
                speedTrainer = st
                activeTempo = updatedTempo
                if previousTempo != updatedTempo {
                    newTempoToNotify = updatedTempo
                    tempoCallbackToDispatch = onTempoChanged
                }
            }
        }

        let tickCallback = onTick
        lock.unlock()

        // Advance practice target timer by step duration (which may call onTargetReached -> stop())
        practiceTargetTimer.advance(by: stepInterval)

        // Invoke callbacks outside lock to prevent deadlocks
        if let t = tickToDispatch {
            tickCallback?(t)
        }

        if let mCallback = measureCallbackToDispatch {
            mCallback(newMeasureIndex)
        }

        if let tCallback = tempoCallbackToDispatch, let t = newTempoToNotify {
            tCallback(t)
        }
    }

    private func handleTimerTick() {
        guard state == .playing else { return }

        processTick()

        lock.lock()
        guard state == .playing, let timer = timerSource else {
            lock.unlock()
            return
        }
        let nextInterval = currentStepDuration()
        lock.unlock()

        timer.schedule(deadline: .now() + nextInterval, leeway: .nanoseconds(100_000))
    }

    private func rebuildScheduleIfNeeded() {
        if cachedBuffers.isEmpty {
            cachedBuffers = audioEngine.createCachedBuffers(timbre: timbre)
        }
    }
}
