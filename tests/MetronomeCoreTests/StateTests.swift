import Testing
import Foundation
@testable import MetronomeCore

struct StateTests {
    // MARK: - PracticeTracker Tests
    @Test func testPracticeTrackerSessionAccumulationAndTotal() {
        let testDefaults = UserDefaults(suiteName: "TestPracticeTrackerSuite_\(UUID().uuidString)")!
        let tracker = PracticeTracker(
            userDefaults: testDefaults,
            totalTimeKey: "test_total",
            sessionsKey: "test_sessions"
        )

        #expect(tracker.currentPracticeTime == 0)
        #expect(tracker.totalPracticeTime == 0)
        #expect(!tracker.isRunning)

        tracker.start()
        #expect(tracker.isRunning)
        Thread.sleep(forTimeInterval: 0.05)
        #expect(tracker.currentPracticeTime >= 0.04)

        tracker.pause()
        #expect(!tracker.isRunning)
        let pausedDuration = tracker.currentPracticeTime
        #expect(pausedDuration >= 0.04)

        // Resuming
        tracker.start()
        Thread.sleep(forTimeInterval: 0.05)
        let session = tracker.stop(tempo: 130.0, notes: "Warmup routine")
        #expect(!tracker.isRunning)
        #expect(session != nil)
        #expect(session?.tempo == 130.0)
        #expect(session?.notes == "Warmup routine")
        #expect((session?.duration ?? 0) >= 0.09)
        #expect(tracker.totalPracticeTime >= 0.09)
        #expect(tracker.sessionHistory.count == 1)

        // Verify persistence by initializing a new tracker instance with same defaults
        let restoredTracker = PracticeTracker(
            userDefaults: testDefaults,
            totalTimeKey: "test_total",
            sessionsKey: "test_sessions"
        )
        #expect(restoredTracker.totalPracticeTime == tracker.totalPracticeTime)
        #expect(restoredTracker.sessionHistory.count == 1)
        #expect(restoredTracker.sessionHistory.first?.notes == "Warmup routine")

        // Reset
        restoredTracker.resetAll()
        #expect(restoredTracker.totalPracticeTime == 0)
        #expect(restoredTracker.sessionHistory.isEmpty)
    }

    @Test func testPracticeTrackerThreadSafety() {
        let tracker = PracticeTracker(userDefaults: nil)
        DispatchQueue.concurrentPerform(iterations: 100) { i in
            tracker.start()
            tracker.pause()
            if i % 2 == 0 {
                tracker.stop(tempo: 120.0 + Double(i))
            }
        }
        #expect(tracker.totalPracticeTime >= 0)
    }

    // MARK: - PracticeTargetTimer Tests
    @Test func testPracticeTargetTimerCountdownAndCallbacks() {
        let timer = PracticeTargetTimer(targetDuration: 10.0)
        #expect(timer.remainingTime == 10.0)
        #expect(timer.progress == 0.0)
        #expect(!timer.isFinished)

        timer.start()
        #expect(timer.isRunning)

        final class Box: @unchecked Sendable {
            var lastReportedRemaining: TimeInterval = 10.0
            var reachedTarget = false
        }
        let box = Box()

        timer.onTick = { remaining in
            box.lastReportedRemaining = remaining
        }
        timer.onTargetReached = {
            box.reachedTarget = true
        }

        timer.advance(by: 4.0)
        #expect(abs(timer.remainingTime - 6.0) < 1e-4)
        #expect(abs(timer.progress - 0.4) < 1e-4)
        #expect(abs(box.lastReportedRemaining - 6.0) < 1e-4)
        #expect(!box.reachedTarget)
        #expect(!timer.isFinished)

        timer.advance(by: 6.0)
        #expect(timer.remainingTime == 0.0)
        #expect(timer.progress == 1.0)
        #expect(box.reachedTarget)
        #expect(timer.isFinished)
        #expect(!timer.isRunning)

        // Reset test
        timer.reset()
        #expect(timer.remainingTime == 10.0)
        #expect(!timer.isFinished)
    }

    // MARK: - PracticeStats Tests
    @Test func testPracticeStatsCalculations() {
        let cal = Calendar.current
        let now = Date()
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: now),
              let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: now) else {
            Issue.record("Calendar date generation failed")
            return
        }

        let session1 = PracticeSession(date: twoDaysAgo, duration: 600, tempo: 100)
        let session2 = PracticeSession(date: yesterday, duration: 1200, tempo: 120)
        let session3 = PracticeSession(date: now, duration: 1800, tempo: 140)

        let stats = PracticeStats(sessions: [session1, session2, session3], calendar: cal)

        #expect(stats.totalTime == 3600)
        #expect(stats.totalSessionsCount == 3)
        #expect(stats.averageSessionDuration == 1200)

        // Weighted tempo: (600*100 + 1200*120 + 1800*140) / 3600 = (60000 + 144000 + 252000)/3600 = 456000/3600 = 126.666...
        #expect(abs(stats.weightedAverageTempo - 126.6666) < 1e-3)

        #expect(stats.practiceTime(on: now) == 1800)
        #expect(stats.practiceTime(on: yesterday) == 1200)
        #expect(stats.currentStreak(asOf: now) == 3)

        let summaries = stats.dailySummaries(lastDays: 3, endingAt: now)
        #expect(summaries.count == 3)
        #expect(summaries.last?.totalDuration == 1800)
        #expect(summaries.last?.sessionCount == 1)
        #expect(summaries.last?.averageTempo == 140)
    }

    // MARK: - PresetSlotManager Tests
    @Test func testPresetSlotManagerCRUDAndPersistence() {
        let testDefaults = UserDefaults(suiteName: "TestPresetSuite_\(UUID().uuidString)")!
        let manager = PresetSlotManager(
            userDefaults: testDefaults,
            storageKey: "test_presets",
            initialDefaultPresets: PresetSlotManager.defaultPresets
        )

        #expect(manager.count == 5)
        #expect(manager.allPresets[0].name == "Standard 4/4")

        // Add
        let customPreset = MetronomePreset(
            name: "Flamenco 12/8",
            bpm: 180.0,
            timeSignature: TimeSignature(beatsPerMeasure: 12, beatValue: 8),
            subdivision: .triplet,
            grooveFeel: .straight,
            downbeatPitchMultiplier: 1.6,
            timbre: .rimshot
        )
        manager.add(customPreset, at: 0)
        #expect(manager.count == 6)
        #expect(manager.allPresets[0].name == "Flamenco 12/8")

        // Recall
        let recalled = manager.recall(at: 0)
        #expect(recalled?.id == customPreset.id)
        #expect(manager.selectedPreset?.name == "Flamenco 12/8")

        // Update
        var updated = customPreset
        updated.bpm = 200.0
        #expect(manager.update(updated))
        #expect(manager.recall(id: customPreset.id)?.bpm == 200.0)

        // Move / Reorder
        manager.move(from: 0, to: 2)
        #expect(manager.allPresets[2].id == customPreset.id)

        // Remove
        let removed = manager.remove(id: customPreset.id)
        #expect(removed?.id == customPreset.id)
        #expect(manager.count == 5)

        // JSON Export & Import
        let exportedJSON = try! manager.exportToJSON()
        #expect(exportedJSON.contains("Standard 4/4"))

        let newManager = PresetSlotManager(
            userDefaults: nil,
            storageKey: "temp",
            initialDefaultPresets: []
        )
        #expect(newManager.count == 0)
        try! newManager.importFromJSON(exportedJSON, overwrite: true)
        #expect(newManager.count == 5)
        #expect(newManager.allPresets[0].name == "Standard 4/4")
    }

    @Test func testMetronomePresetPatternSerializationAndBackwardCompatibility() throws {
        // 1. Full preset with custom pattern and pitch semitones
        let customPattern = MeasurePattern(
            timeSignature: TimeSignature(beatsPerMeasure: 3, beatValue: 4),
            subdivision: .triplet,
            steps: [.downbeat, .ghost, .mute, .accent, .normal, .ghost, .normal, .ghost, .mute]
        )
        let presetWithPattern = MetronomePreset(
            name: "Complex Polyrhythm Preset",
            bpm: 135.0,
            timeSignature: TimeSignature(beatsPerMeasure: 3, beatValue: 4),
            subdivision: .triplet,
            grooveFeel: .standardSwing,
            downbeatPitchMultiplier: 1.5,
            timbre: .woodblock,
            pattern: customPattern,
            downbeatPitchSemitones: 12.0
        )

        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(presetWithPattern)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MetronomePreset.self, from: encodedData)

        #expect(decoded.name == "Complex Polyrhythm Preset")
        #expect(decoded.bpm == 135.0)
        #expect(decoded.pattern == customPattern)
        #expect(decoded.pattern?.steps == customPattern.steps)
        #expect(decoded.downbeatPitchSemitones == 12.0)

        // 2. Backward compatibility test: decode legacy JSON payload without pattern and downbeatPitchSemitones
        let legacyJSON = """
        {
            "id": "\(UUID().uuidString)",
            "name": "Legacy Preset",
            "bpm": 128.0,
            "timeSignature": {
                "beatsPerMeasure": 4,
                "beatValue": 4
            },
            "subdivision": "quarter",
            "grooveFeel": {
                "shuffleRatio": 0.5
            },
            "downbeatPitchMultiplier": 1.5,
            "timbre": "woodblock",
            "createdAt": 748000000.0,
            "updatedAt": 748000000.0
        }
        """

        let legacyData = legacyJSON.data(using: .utf8)!
        let legacyDecoded = try decoder.decode(MetronomePreset.self, from: legacyData)
        #expect(legacyDecoded.name == "Legacy Preset")
        #expect(legacyDecoded.bpm == 128.0)
        #expect(legacyDecoded.pattern == nil)
        #expect(legacyDecoded.downbeatPitchSemitones == nil)
    }
}
