import Foundation
import SwiftUI
import Combine
import MetronomeCore

/// ViewModel orchestrating SwiftUI Metronome UI state with the high-performance MetronomeEngine.
@MainActor
public final class MetronomeViewModel: ObservableObject {
    // MARK: - Published UI State
    
    @Published public var bpm: Double = 120.0 {
        didSet {
            let clamped = min(max(bpm, Tempo.minBPM), Tempo.maxBPM)
            if clamped != bpm {
                bpm = clamped
            }
            if engine.tempo.bpm != bpm {
                engine.setTempo(Tempo(bpm: bpm))
            }
            updateTempoMarking()
        }
    }
    
    @Published public private(set) var playbackState: MetronomePlaybackState = .stopped
    @Published public var timeSignature: TimeSignature = .common {
        didSet {
            updatePatternForNewRhythm()
        }
    }
    @Published public var subdivision: Subdivision = .quarter {
        didSet {
            updatePatternForNewRhythm()
        }
    }
    @Published public var grooveFeel: GrooveFeel = .straight {
        didSet {
            engine.setGrooveFeel(grooveFeel)
        }
    }
    @Published public var pattern: MeasurePattern = MeasurePattern() {
        didSet {
            engine.setPattern(pattern)
        }
    }
    @Published public var timbre: Timbre = .woodblock {
        didSet {
            engine.timbre = timbre
        }
    }
    @Published public var volume: Float = 0.8 {
        didSet {
            engine.setVolume(volume)
        }
    }
    @Published public var isMuted: Bool = false {
        didSet {
            engine.setMuted(isMuted)
        }
    }
    
    // Playback visual indicators
    @Published public private(set) var currentStepIndex: Int = 0
    @Published public private(set) var currentBeatIndex: Int = 0
    @Published public private(set) var currentSubdivisionIndex: Int = 0
    @Published public private(set) var currentEmphasis: BeatEmphasis = .normal
    @Published public private(set) var currentMeasureNumber: Int = 0
    @Published public private(set) var isBeatFlashing: Bool = false
    @Published public private(set) var isDownbeatFlashing: Bool = false
    @Published public private(set) var tapTempoTriggered: Bool = false
    @Published public private(set) var tempoMarking: String = "Moderato"
    @Published public private(set) var pendulumPhase: Double = 0.0 // -1.0 (left) to 1.0 (right)
    
    // MARK: - Preset Slots State
    public let presetSlotManager: PresetSlotManager
    @Published public var presets: [MetronomePreset] = []
    @Published public var selectedPresetId: UUID? = nil
    
    // MARK: - Sound & Downbeat Settings State
    @Published public var downbeatPitchSemitones: Double = 7.0 {
        didSet {
            engine.audioEngine.synthesizer.downbeatPitch = DownbeatPitch(semitoneOffset: downbeatPitchSemitones)
            engine.timbre = timbre // Rebuild cache
        }
    }
    
    // MARK: - Drone Tuner State
    @Published public var isDronePlaying: Bool = false
    @Published public var droneFrequency: Double = 440.0 {
        didSet {
            droneReference.baseFrequency = droneFrequency
        }
    }
    @Published public var droneVolume: Float = 0.5 {
        didSet {
            droneReference.volume = droneVolume
        }
    }
    private lazy var droneReference: ReferenceDrone = {
        ReferenceDrone(engine: engine.audioEngine.engine, baseFrequency: droneFrequency)
    }()
    
    // MARK: - Speed Trainer State
    @Published public var isSpeedTrainerActive: Bool = false {
        didSet {
            updateSpeedTrainerInEngine()
        }
    }
    @Published public var speedTrainerStartBPM: Double = 100.0
    @Published public var speedTrainerTargetBPM: Double = 160.0
    @Published public var speedTrainerStepBPM: Double = 5.0
    @Published public var speedTrainerStepMeasures: Int = 4
    @Published public var speedTrainerLoop: Bool = false
    
    // MARK: - Gap Trainer State
    @Published public var isGapTrainerActive: Bool = false {
        didSet {
            updateGapTrainerInEngine()
        }
    }
    @Published public var gapTrainerModeIndex: Int = 0 // 0: Bars, 1: Random
    @Published public var gapTrainerSoundBars: Int = 3
    @Published public var gapTrainerSilentBars: Int = 1
    @Published public var gapTrainerMuteProbability: Double = 0.25
    
    // MARK: - UI Presentation State (Pro Tools Drawer & Settings Sheet)
    @Published public var isToolsDrawerOpen: Bool = false
    @Published public var selectedToolsTab: ToolsTab = .speedTrainer
    @Published public var isSoundSettingsPresented: Bool = false

    // MARK: - Practice Tracking & Target Timer State
    @Published public var currentPracticeTime: TimeInterval = 0
    @Published public var totalPracticeTime: TimeInterval = 0
    @Published public var targetCountdownDuration: TimeInterval = 0
    @Published public var targetCountdownRemaining: TimeInterval = 0
    @Published public var isTargetTimerRunning: Bool = false
    @Published public var isTargetTimerFinished: Bool = false
    @Published public var isTargetTimerExpanded: Bool = false
    
    // MARK: - Internal Engine
    public let engine: MetronomeEngine
    private var flashTimerTask: Task<Void, Never>?
    private var pendulumAnimationTimer: Timer?
    private var practiceStatsTimer: Timer?
    private var lastTickTimestamp: TimeInterval = 0
    private var tickDuration: TimeInterval = 0.5
    private var pendulumDirection: Double = 1.0
    
    // MARK: - Initialization
    public init(
        engine: MetronomeEngine = MetronomeEngine(),
        presetSlotManager: PresetSlotManager = PresetSlotManager(initialDefaultPresets: PresetSlotManager.defaultPresets)
    ) {
        self.engine = engine
        self.presetSlotManager = presetSlotManager
        self.bpm = engine.tempo.bpm
        self.timeSignature = engine.pattern.timeSignature
        self.subdivision = engine.pattern.subdivision
        self.pattern = engine.pattern
        self.grooveFeel = engine.grooveFeel
        self.timbre = engine.timbre
        self.isMuted = engine.isMuted
        self.volume = engine.audioEngine.volume
        
        self.presets = presetSlotManager.allPresets
        self.selectedPresetId = presetSlotManager.selectedPreset?.id
        self.totalPracticeTime = engine.practiceTracker.totalPracticeTime
        
        updateTempoMarking()
        bindEngineCallbacks()
        startPracticeStatsTimer()
    }
    
    // MARK: - Engine Callbacks Binding
    private func bindEngineCallbacks() {
        engine.onTick = { [weak self] tick in
            Task { @MainActor in
                self?.handleEngineTick(tick)
            }
        }
        
        engine.onPlaybackStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.playbackState = state
                if state == .stopped {
                    self?.resetVisuals()
                }
            }
        }
        
        engine.onMeasureChanged = { [weak self] measureIndex in
            Task { @MainActor in
                self?.currentMeasureNumber = measureIndex
            }
        }
        
        engine.onTempoChanged = { [weak self] newTempo in
            Task { @MainActor in
                if self?.bpm != newTempo.bpm {
                    self?.bpm = newTempo.bpm
                }
            }
        }
    }
    
    // MARK: - Real-time Tick Handling
    private func handleEngineTick(_ tick: MetronomeTick) {
        currentStepIndex = tick.event.stepIndexInMeasure
        currentBeatIndex = tick.event.beatIndex
        currentSubdivisionIndex = tick.event.subdivisionIndex
        currentEmphasis = tick.event.emphasis
        currentMeasureNumber = tick.currentMeasure
        lastTickTimestamp = tick.timestamp
        tickDuration = max(0.01, tick.event.duration)
        
        // Pendulum oscillation target flip on primary beat
        if tick.event.subdivisionIndex == 0 {
            pendulumDirection = (tick.event.beatIndex % 2 == 0) ? 1.0 : -1.0
        }
        
        // Trigger LED visual flash
        flashVisualIndicators(emphasis: tick.event.emphasis)
    }
    
    private func flashVisualIndicators(emphasis: BeatEmphasis) {
        flashTimerTask?.cancel()
        isBeatFlashing = true
        isDownbeatFlashing = (emphasis == .downbeat)
        
        flashTimerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000) // 80ms flash
            self.isBeatFlashing = false
            self.isDownbeatFlashing = false
        }
    }
    
    private func resetVisuals() {
        currentStepIndex = 0
        currentBeatIndex = 0
        currentSubdivisionIndex = 0
        currentEmphasis = .normal
        currentMeasureNumber = 0
        isBeatFlashing = false
        isDownbeatFlashing = false
        pendulumPhase = 0.0
    }
    
    // MARK: - Transport Actions
    public func togglePlayPause() {
        if playbackState == .playing {
            pause()
        } else {
            play()
        }
    }
    
    public func play() {
        do {
            try engine.start()
            playbackState = .playing
        } catch {
            print("Failed to start MetronomeEngine: \(error)")
        }
    }
    
    public func pause() {
        engine.pause()
        playbackState = .paused
    }
    
    public func stop() {
        engine.stop()
        playbackState = .stopped
        resetVisuals()
    }
    
    // MARK: - Tap Tempo
    public func tapTempo() {
        tapTempoTriggered = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            self.tapTempoTriggered = false
        }
        
        if let newTempo = engine.tapTempo() {
            self.bpm = newTempo.bpm
        }
    }
    
    public func resetTapTempo() {
        engine.resetTapTempo()
    }
    
    // MARK: - BPM Adjustments
    public func incrementBpm(_ delta: Double) {
        bpm = min(max(bpm + delta, Tempo.minBPM), Tempo.maxBPM)
    }
    
    public func setBpm(_ newBpm: Double) {
        bpm = min(max(newBpm, Tempo.minBPM), Tempo.maxBPM)
    }
    
    private func updateTempoMarking() {
        switch bpm {
        case ..<40:
            tempoMarking = "Grave"
        case 40..<60:
            tempoMarking = "Largo"
        case 60..<66:
            tempoMarking = "Larghetto"
        case 66..<76:
            tempoMarking = "Adagio"
        case 76..<108:
            tempoMarking = "Andante"
        case 108..<120:
            tempoMarking = "Moderato"
        case 120..<168:
            tempoMarking = "Allegro"
        case 168..<200:
            tempoMarking = "Presto"
        default:
            tempoMarking = "Prestissimo"
        }
    }
    
    // MARK: - Rhythm & Pattern Configuration
    private func updatePatternForNewRhythm() {
        let newPattern = MeasurePattern(timeSignature: timeSignature, subdivision: subdivision)
        pattern = newPattern
    }
    
    public func toggleStepEmphasis(at index: Int) {
        guard index >= 0 && index < pattern.steps.count else { return }
        let current = pattern.steps[index]
        let next: BeatEmphasis
        switch current {
        case .downbeat: next = .accent
        case .accent:   next = .normal
        case .normal:   next = .ghost
        case .ghost:    next = .mute
        case .mute:     next = .downbeat
        }
        var updatedSteps = pattern.steps
        updatedSteps[index] = next
        pattern = MeasurePattern(timeSignature: timeSignature, subdivision: subdivision, steps: updatedSteps)
    }
    
    public func setStepEmphasis(_ emphasis: BeatEmphasis, at index: Int) {
        guard index >= 0 && index < pattern.steps.count else { return }
        var updatedSteps = pattern.steps
        updatedSteps[index] = emphasis
        pattern = MeasurePattern(timeSignature: timeSignature, subdivision: subdivision, steps: updatedSteps)
    }
    
    public func resetPatternToDefault() {
        updatePatternForNewRhythm()
    }
    
    public func setAllStepsEmphasis(_ emphasis: BeatEmphasis) {
        let count = pattern.totalSteps
        let updatedSteps = Array(repeating: emphasis, count: count)
        pattern = MeasurePattern(timeSignature: timeSignature, subdivision: subdivision, steps: updatedSteps)
    }
    
    public func setGrooveShuffleRatio(_ ratio: Double) {
        grooveFeel = GrooveFeel(shuffleRatio: ratio)
    }
    
    public func toggleMute() {
        isMuted.toggle()
    }
    
    // MARK: - Preset Slot Operations
    
    public func reloadPresets() {
        presets = presetSlotManager.allPresets
        selectedPresetId = presetSlotManager.selectedPreset?.id
    }
    
    public func recallPreset(_ preset: MetronomePreset) {
        if let recalled = presetSlotManager.recall(id: preset.id) {
            applyPreset(recalled)
        }
    }
    
    public func recallPreset(at slotIndex: Int) {
        // 1-indexed (1..9)
        let arrayIndex = slotIndex - 1
        guard arrayIndex >= 0 && arrayIndex < presets.count else { return }
        if let recalled = presetSlotManager.recall(at: arrayIndex) {
            applyPreset(recalled)
        }
    }
    
    private func applyPreset(_ preset: MetronomePreset) {
        self.bpm = preset.bpm
        self.timeSignature = preset.timeSignature
        self.subdivision = preset.subdivision
        self.grooveFeel = preset.grooveFeel
        self.timbre = preset.timbre
        self.selectedPresetId = preset.id
        self.reloadPresets()
    }
    
    public func saveCurrentAsPreset(name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanName.isEmpty ? "Slot \(presets.count + 1)" : cleanName
        let newPreset = MetronomePreset(
            name: finalName,
            bpm: self.bpm,
            timeSignature: self.timeSignature,
            subdivision: self.subdivision,
            grooveFeel: self.grooveFeel,
            downbeatPitchMultiplier: 1.5,
            timbre: self.timbre
        )
        presetSlotManager.add(newPreset)
        _ = presetSlotManager.recall(id: newPreset.id)
        reloadPresets()
    }
    
    public func overwritePresetWithCurrentState(id: UUID) {
        guard let existing = presets.first(where: { $0.id == id }) else { return }
        let updated = MetronomePreset(
            id: existing.id,
            name: existing.name,
            bpm: self.bpm,
            timeSignature: self.timeSignature,
            subdivision: self.subdivision,
            grooveFeel: self.grooveFeel,
            downbeatPitchMultiplier: existing.downbeatPitchMultiplier,
            timbre: self.timbre,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )
        presetSlotManager.update(updated)
        reloadPresets()
    }
    
    public func renamePreset(id: UUID, newName: String) {
        guard var existing = presets.first(where: { $0.id == id }) else { return }
        let clean = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        existing.name = clean
        presetSlotManager.update(existing)
        reloadPresets()
    }
    
    public func deletePreset(id: UUID) {
        presetSlotManager.remove(id: id)
        reloadPresets()
    }
    
    // MARK: - Practice Tracker & Target Countdown Timer
    
    private func startPracticeStatsTimer() {
        practiceStatsTimer?.invalidate()
        practiceStatsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePracticeStats()
            }
        }
    }
    
    private func updatePracticeStats() {
        currentPracticeTime = engine.practiceTracker.currentPracticeTime
        totalPracticeTime = engine.practiceTracker.totalPracticeTimeWithCurrentSession
        
        if isTargetTimerRunning {
            engine.practiceTargetTimer.tick()
            targetCountdownRemaining = engine.practiceTargetTimer.remainingTime
            if engine.practiceTargetTimer.isFinished {
                isTargetTimerRunning = false
                isTargetTimerFinished = true
            }
        } else {
            targetCountdownRemaining = engine.practiceTargetTimer.remainingTime
            targetCountdownDuration = engine.practiceTargetTimer.targetDuration
            isTargetTimerFinished = engine.practiceTargetTimer.isFinished
        }
    }
    
    public func resetCurrentPracticeSession() {
        engine.practiceTracker.resetCurrentSession()
        currentPracticeTime = 0
    }
    
    public func setTargetCountdownDuration(_ duration: TimeInterval) {
        engine.practiceTargetTimer.setTargetDuration(duration)
        targetCountdownDuration = duration
        targetCountdownRemaining = duration
        isTargetTimerFinished = false
    }
    
    public func toggleTargetTimer() {
        if isTargetTimerRunning {
            pauseTargetTimer()
        } else {
            startTargetTimer()
        }
    }
    
    public func startTargetTimer() {
        guard targetCountdownDuration > 0 else { return }
        if isTargetTimerFinished {
            engine.practiceTargetTimer.reset()
            isTargetTimerFinished = false
        }
        engine.practiceTargetTimer.start()
        isTargetTimerRunning = true
    }
    
    public func pauseTargetTimer() {
        engine.practiceTargetTimer.pause()
        isTargetTimerRunning = false
    }
    
    public func resetTargetTimer() {
        engine.practiceTargetTimer.reset()
        targetCountdownRemaining = targetCountdownDuration
        isTargetTimerRunning = false
        isTargetTimerFinished = false
    }
    
    public func toggleTargetTimerExpanded() {
        isTargetTimerExpanded.toggle()
    }
    
    // MARK: - Speed & Gap Trainer Configuration Helpers
    
    public func updateSpeedTrainerInEngine() {
        if isSpeedTrainerActive {
            let config = SpeedTrainerConfig(
                startBPM: speedTrainerStartBPM,
                targetBPM: speedTrainerTargetBPM,
                stepBPM: speedTrainerStepBPM,
                stepIntervalMeasures: speedTrainerStepMeasures,
                loopOnComplete: speedTrainerLoop
            )
            engine.speedTrainer = SpeedTrainer(config: config)
        } else {
            engine.speedTrainer = nil
            engine.setTempo(Tempo(bpm: bpm))
        }
    }
    
    public func updateGapTrainerInEngine() {
        if isGapTrainerActive {
            let mode: GapTrainerMode
            if gapTrainerModeIndex == 0 {
                mode = .barPattern(soundBars: gapTrainerSoundBars, silentBars: gapTrainerSilentBars)
            } else {
                mode = .randomGap(muteProbability: gapTrainerMuteProbability)
            }
            engine.gapTrainer = GapTrainer(mode: mode)
        } else {
            engine.gapTrainer = nil
        }
    }
    
    // MARK: - Drone Tuner Controls
    
    public func toggleDrone() {
        if isDronePlaying {
            stopDrone()
        } else {
            startDrone()
        }
    }
    
    public func startDrone() {
        do {
            try droneReference.start()
            isDronePlaying = true
        } catch {
            print("Failed to start Reference Drone: \(error)")
        }
    }
    
    public func stopDrone() {
        droneReference.stop()
        isDronePlaying = false
    }
    
    public func setDronePitch(frequency: Double) {
        droneFrequency = max(20.0, min(2000.0, frequency))
    }
    
    // MARK: - UI Presentation Controls
    
    public func toggleToolsDrawer() {
        isToolsDrawerOpen.toggle()
    }
    
    public func toggleSoundSettings() {
        isSoundSettingsPresented.toggle()
    }
}

/// Tabs available within the Pro Tools Drawer
public enum ToolsTab: String, CaseIterable, Identifiable, Sendable {
    case speedTrainer = "Speed Trainer"
    case gapTrainer = "Gap Trainer"
    case droneTuner = "Drone Tuner"
    case practiceStats = "Practice Stats"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .speedTrainer: return "gauge.with.dots.needle.bottom.50percent"
        case .gapTrainer: return "waveform.slash"
        case .droneTuner: return "tuningfork"
        case .practiceStats: return "chart.bar.xaxis"
        }
    }
}
