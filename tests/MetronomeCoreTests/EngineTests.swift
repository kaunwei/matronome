import Testing
import Foundation
#if os(macOS)
import AppKit
#endif
@testable import MetronomeCore

final class TestBox<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T

    init(_ value: T) {
        self._value = value
    }

    var value: T {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func mutate(_ transform: (inout T) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&_value)
    }
}

struct EngineTests {

    @Test func testEngineInitialState() {
        let engine = MetronomeEngine(tempo: Tempo(bpm: 120), pattern: MeasurePattern(timeSignature: .common))
        #expect(engine.state == .stopped)
        #expect(engine.tempo.bpm == 120)
        #expect(engine.activeTempo.bpm == 120)
        #expect(engine.isMuted == false)
    }

    @Test func testEngineStartPauseStopLifecycle() throws {
        let engine = MetronomeEngine(tempo: Tempo(bpm: 120))
        let recordedStates = TestBox<[MetronomePlaybackState]>([])
        engine.onPlaybackStateChanged = { state in
            recordedStates.mutate { $0.append(state) }
        }

        try engine.start()
        #expect(engine.state == .playing)
        #expect(recordedStates.value.contains(.playing))

        engine.pause()
        #expect(engine.state == .paused)
        #expect(recordedStates.value.contains(.paused))

        try engine.start()
        #expect(engine.state == .playing)

        engine.stop()
        #expect(engine.state == .stopped)
        #expect(recordedStates.value.last == .stopped)
    }

    @Test func testProcessTickCallbacksAndMeasureProgression() {
        let pattern = MeasurePattern(timeSignature: TimeSignature(beatsPerMeasure: 4, beatValue: 4), subdivision: .quarter)
        let engine = MetronomeEngine(tempo: Tempo(bpm: 120), pattern: pattern)

        let ticks = TestBox<[MetronomeTick]>([])
        let measureChanges = TestBox<[Int]>([])

        engine.onTick = { tick in
            ticks.mutate { $0.append(tick) }
        }
        engine.onMeasureChanged = { measure in
            measureChanges.mutate { $0.append(measure) }
        }

        // Process 4 quarter notes = 1 full measure
        for _ in 0..<4 {
            engine.processTick()
        }

        #expect(ticks.value.count == 4)
        #expect(ticks.value[0].event.beatIndex == 0)
        #expect(ticks.value[0].event.emphasis == .downbeat)
        #expect(ticks.value[1].event.beatIndex == 1)
        #expect(ticks.value[1].event.emphasis == .normal)
        #expect(measureChanges.value == [1])

        // Process another 4 quarter notes = 2nd measure
        for _ in 0..<4 {
            engine.processTick()
        }

        #expect(ticks.value.count == 8)
        #expect(measureChanges.value == [1, 2])
    }

    @Test func testLiveParameterAdjustments() {
        let engine = MetronomeEngine(tempo: Tempo(bpm: 100))
        #expect(engine.tempo.bpm == 100)

        engine.setTempo(Tempo(bpm: 140))
        #expect(engine.tempo.bpm == 140)
        #expect(engine.activeTempo.bpm == 140)

        let newPattern = MeasurePattern(timeSignature: .waltz, subdivision: .eighth)
        engine.setPattern(newPattern)
        #expect(engine.pattern.totalSteps == 6)

        engine.setGrooveFeel(.standardSwing)
        #expect(engine.grooveFeel == .standardSwing)

        engine.setMuted(true)
        #expect(engine.isMuted == true)
    }

    @Test func testTapTempoIntegration() {
        let engine = MetronomeEngine(tempo: Tempo(bpm: 120))
        let initialTime = 1000.0

        // Tap 1
        #expect(engine.tapTempo(at: initialTime) == nil)

        // Tap 2 at +0.5s => 120 BPM
        let t2 = engine.tapTempo(at: initialTime + 0.5)
        #expect(t2?.bpm == 120)
        #expect(engine.tempo.bpm == 120)

        // Tap 3 at +1.0s => 120 BPM
        let t3 = engine.tapTempo(at: initialTime + 1.0)
        #expect(t3?.bpm == 120)

        // Reset tap
        engine.resetTapTempo()
        #expect(engine.tapTempo(at: initialTime + 2.0) == nil)
    }

    @Test func testSpeedTrainerOrchestration() {
        let config = SpeedTrainerConfig(startBPM: 100, targetBPM: 120, stepBPM: 10, stepIntervalMeasures: 2)
        let trainer = SpeedTrainer(config: config)
        let pattern = MeasurePattern(timeSignature: TimeSignature(beatsPerMeasure: 2, beatValue: 4), subdivision: .quarter)

        let engine = MetronomeEngine(tempo: Tempo(bpm: 100), pattern: pattern)
        engine.speedTrainer = trainer

        #expect(engine.activeTempo.bpm == 100)

        let tempoUpdates = TestBox<[Double]>([])
        engine.onTempoChanged = { tempo in
            tempoUpdates.mutate { $0.append(tempo.bpm) }
        }

        // Measure 0: 2 beats (completes measure 1 of trainer)
        engine.processTick()
        engine.processTick()
        #expect(engine.activeTempo.bpm == 100)

        // Measure 1: 2 beats (completes measure 2 of trainer -> step boundary reached -> 110)
        engine.processTick()
        engine.processTick()
        #expect(engine.activeTempo.bpm == 110)
        #expect(tempoUpdates.value.contains(110))

        // Measure 2: 2 beats (completes measure 3 of trainer)
        engine.processTick()
        engine.processTick()
        #expect(engine.activeTempo.bpm == 110)

        // Measure 3: 2 beats (completes measure 4 of trainer -> step boundary reached -> 120)
        engine.processTick()
        engine.processTick()
        #expect(engine.activeTempo.bpm == 120)
        #expect(tempoUpdates.value.contains(120))
    }

    @Test func testGapTrainerOrchestration() {
        // 1 sound bar, 1 silent bar
        let gt = GapTrainer(mode: .barPattern(soundBars: 1, silentBars: 1))
        let pattern = MeasurePattern(timeSignature: TimeSignature(beatsPerMeasure: 2, beatValue: 4), subdivision: .quarter)
        let engine = MetronomeEngine(tempo: Tempo(bpm: 120), pattern: pattern)
        engine.gapTrainer = gt

        let tickMutes = TestBox<[Bool]>([])
        engine.onTick = { tick in
            tickMutes.mutate { $0.append(tick.isMuted) }
        }

        // Measure 0 (sound)
        engine.processTick()
        engine.processTick()

        // Measure 1 (gap/muted)
        engine.processTick()
        engine.processTick()

        #expect(tickMutes.value == [false, false, true, true])
    }

    @Test func testPracticeTargetTimerIntegration() {
        // Verify countdown is decoupled from audio subdivision steps:
        // Calling processTick() does NOT double-decrement or advance the target timer.
        let pattern = MeasurePattern(timeSignature: TimeSignature(beatsPerMeasure: 4, beatValue: 4), subdivision: .sixteenth)
        let engine = MetronomeEngine(tempo: Tempo(bpm: 240), pattern: pattern)
        engine.practiceTargetTimer.setTargetDuration(5.0)
        engine.practiceTargetTimer.start()

        let initialRemaining = engine.practiceTargetTimer.remainingTime
        // Execute 16 sixteenth-note ticks (1 full measure at 240 BPM)
        for _ in 0..<16 {
            engine.processTick()
        }
        // Subdivisions must NOT decrement the timer by stepInterval
        #expect(abs(engine.practiceTargetTimer.remainingTime - initialRemaining) < 0.1)
    }

    @Test func testMetronomeStopsWhenPracticeTargetTimerReachesZero() async throws {
        let pattern = MeasurePattern(timeSignature: TimeSignature(beatsPerMeasure: 4, beatValue: 4), subdivision: .quarter)
        let engine = MetronomeEngine(tempo: Tempo(bpm: 240), pattern: pattern)

        // Set a short target duration of 0.1s
        engine.practiceTargetTimer.setTargetDuration(0.1)
        try engine.start()
        #expect(engine.state == .playing)

        // Wait up to 1.0s for the target timer to reach 0 and stop the engine
        let startWait = ProcessInfo.processInfo.systemUptime
        while engine.state == .playing && (ProcessInfo.processInfo.systemUptime - startWait) < 1.0 {
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        #expect(engine.state == .stopped)
        #expect(engine.practiceTargetTimer.remainingTime == 0.0)
        #expect(engine.practiceTargetTimer.isFinished)
    }

    @Test func testPracticeTrackerRecording() {
        let tracker = PracticeTracker(userDefaults: nil)
        let engine = MetronomeEngine(practiceTracker: tracker, tempo: Tempo(bpm: 130))

        try? engine.start()
        #expect(tracker.isRunning == true)

        engine.stop()
        #expect(tracker.isRunning == false)
    }

    @Test func testMetronomeEngineAudioResetWhileStopped() {
        let engine = MetronomeEngine(tempo: Tempo(bpm: 120))
        #expect(engine.state == .stopped)

        // Reset audio while stopped
        engine.handleAudioReset(force: true)
        #expect(engine.state == .stopped)
        #expect(engine.audioEngine.isRunning == false)
    }

    @Test func testMetronomeEngineAudioResetWhilePlayingResumesPlayback() throws {
        let engine = MetronomeEngine(tempo: Tempo(bpm: 120))
        try engine.start()
        #expect(engine.state == .playing)
        #expect(engine.audioEngine.isRunning == true)

        // Simulate wake or audio device switch reset
        engine.handleAudioReset(force: true)

        // Engine must remain playing and audio graph restarted
        #expect(engine.state == .playing)
        #expect(engine.audioEngine.isRunning == true)

        // Ticks must process cleanly without throwing or crashing
        engine.processTick()

        engine.stop()
        #expect(engine.state == .stopped)
    }

    @Test func testMetronomeEngineSleepWakeAndAudioConfigNotifications() async throws {
        let engine = MetronomeEngine(tempo: Tempo(bpm: 120))
        try engine.start()
        #expect(engine.state == .playing)

        // Post AVAudioEngineConfigurationChange notification
        NotificationCenter.default.post(
            name: .AVAudioEngineConfigurationChange,
            object: engine.audioEngine.engine
        )

        #if os(macOS)
        // Post NSWorkspace.didWakeNotification
        NotificationCenter.default.post(
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        #endif

        // Wait briefly for asynchronous audio reset queue to execute without deadlock
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        #expect(engine.state == .playing)
        engine.processTick()

        engine.stop()
        #expect(engine.state == .stopped)
    }
}
