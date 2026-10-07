import Testing
@testable import MetronomeCore

struct RhythmTests {
    // MARK: - Tempo Tests
    @Test func testTempoValidationAndClamping() {
        let defaultTempo = Tempo()
        #expect(defaultTempo.bpm == 120.0)
        #expect(abs(defaultTempo.secondsPerBeat - 0.5) < 1e-6)

        let belowMin = Tempo(bpm: 10.0)
        #expect(belowMin.bpm == 20.0)

        let aboveMax = Tempo(bpm: 500.0)
        #expect(aboveMax.bpm == 400.0)

        let validTempo = Tempo(bpm: 140.0)
        #expect(validTempo.bpm == 140.0)
        #expect(abs(validTempo.secondsPerBeat - (60.0 / 140.0)) < 1e-6)
    }

    @Test func testTapTempoCalculator() {
        var calculator = TapTempoCalculator(maxTapHistory: 4, timeoutInterval: 2.0)
        #expect(calculator.tap(at: 100.0) == nil)

        // 120 BPM = 0.5s intervals
        let t1 = calculator.tap(at: 100.5)
        #expect(t1?.bpm == 120.0)

        let t2 = calculator.tap(at: 101.0)
        #expect(t2?.bpm == 120.0)

        let t3 = calculator.tap(at: 101.5)
        #expect(t3?.bpm == 120.0)

        // Timeout resets history
        let t4 = calculator.tap(at: 105.0)
        #expect(t4 == nil)

        // 60 BPM = 1.0s interval
        let t5 = calculator.tap(at: 106.0)
        #expect(t5?.bpm == 60.0)
    }

    // MARK: - TimeSignature Tests
    @Test func testTimeSignature() {
        let ts44 = TimeSignature.common
        #expect(ts44.beatsPerMeasure == 4)
        #expect(ts44.beatValue == 4)
        #expect(ts44.description == "4/4")

        let ts68 = TimeSignature.sixEight
        #expect(ts68.beatsPerMeasure == 6)
        #expect(ts68.beatValue == 8)
        #expect(ts68.description == "6/8")

        let custom33 = TimeSignature(beatsPerMeasure: 3, beatValue: 3)
        #expect(custom33.beatsPerMeasure == 3)
        #expect(custom33.beatValue == 3)
        #expect(custom33.description == "3/3")

        let invalid = TimeSignature(beatsPerMeasure: 0, beatValue: 0)
        #expect(invalid.beatsPerMeasure == 1)
        #expect(invalid.beatValue == 1)
    }

    // MARK: - Subdivision Tests
    @Test func testSubdivisionPulses() {
        #expect(Subdivision.quarter.pulsesPerBeat == 1)
        #expect(Subdivision.eighth.pulsesPerBeat == 2)
        #expect(Subdivision.triplet.pulsesPerBeat == 3)
        #expect(Subdivision.sixteenth.pulsesPerBeat == 4)
        #expect(Subdivision.sextuplet.pulsesPerBeat == 6)
    }

    // MARK: - GrooveFeel Tests
    @Test func testGrooveFeelClamping() {
        let straight = GrooveFeel.straight
        #expect(straight.isStraight)
        #expect(straight.shuffleRatio == 0.50)

        let clampedLow = GrooveFeel(shuffleRatio: 0.30)
        #expect(clampedLow.shuffleRatio == 0.50)

        let clampedHigh = GrooveFeel(shuffleRatio: 0.90)
        #expect(clampedHigh.shuffleRatio == 0.75)

        let tripletSwing = GrooveFeel.standardSwing
        #expect(abs(tripletSwing.shuffleRatio - (2.0 / 3.0)) < 1e-4)
    }

    // MARK: - BeatEmphasis Tests
    @Test func testBeatEmphasisProperties() {
        #expect(BeatEmphasis.downbeat.isAudible)
        #expect(BeatEmphasis.accent.isAudible)
        #expect(BeatEmphasis.normal.isAudible)
        #expect(BeatEmphasis.ghost.isAudible)
        #expect(!BeatEmphasis.mute.isAudible)

        #expect(BeatEmphasis.downbeat.gainMultiplier > BeatEmphasis.accent.gainMultiplier)
        #expect(BeatEmphasis.accent.gainMultiplier > BeatEmphasis.normal.gainMultiplier)
        #expect(BeatEmphasis.normal.gainMultiplier > BeatEmphasis.ghost.gainMultiplier)
        #expect(BeatEmphasis.mute.gainMultiplier == 0.0)
    }

    // MARK: - MeasurePattern Tests
    @Test func testMeasurePatternInitialization() {
        let defaultPattern = MeasurePattern(timeSignature: .common, subdivision: .quarter)
        #expect(defaultPattern.totalSteps == 4)
        #expect(defaultPattern.steps == [.downbeat, .normal, .normal, .normal])

        let eighthPattern = MeasurePattern(timeSignature: .waltz, subdivision: .eighth)
        #expect(eighthPattern.totalSteps == 6)
        #expect(eighthPattern.steps == [.downbeat, .ghost, .normal, .ghost, .normal, .ghost])

        var customPattern = MeasurePattern(timeSignature: .march, subdivision: .quarter, steps: [.accent, .mute])
        #expect(customPattern.steps == [.accent, .mute])
        customPattern[1] = .ghost
        #expect(customPattern[1] == .ghost)
        #expect(customPattern[3] == .ghost) // wrapped modulo access
    }

    // MARK: - RhythmEventScheduler Tests
    @Test func testRhythmEventSchedulerStraightEvents() {
        let scheduler = RhythmEventScheduler()
        let tempo = Tempo(bpm: 120.0) // 0.5s per beat
        let pattern = MeasurePattern(timeSignature: .common, subdivision: .quarter) // 4 beats, 4 steps

        let events = scheduler.scheduleEvents(
            tempo: tempo,
            pattern: pattern,
            grooveFeel: .straight,
            numberOfMeasures: 2,
            startingTimeOffset: 0.0
        )

        #expect(events.count == 8)
        #expect(abs(events[0].timeOffset - 0.0) < 1e-6)
        #expect(abs(events[0].duration - 0.5) < 1e-6)
        #expect(events[0].emphasis == .downbeat)
        #expect(events[0].measureIndex == 0)
        #expect(events[0].beatIndex == 0)

        #expect(abs(events[4].timeOffset - 2.0) < 1e-6)
        #expect(events[4].emphasis == .downbeat)
        #expect(events[4].measureIndex == 1)
        #expect(events[4].beatIndex == 0)

        #expect(abs(events[7].timeOffset - 3.5) < 1e-6)
        #expect(events[7].measureIndex == 1)
        #expect(events[7].beatIndex == 3)
    }

    @Test func testRhythmEventSchedulerShuffleSubdivisions() {
        let scheduler = RhythmEventScheduler()
        let tempo = Tempo(bpm: 120.0) // 0.5s per beat
        let pattern = MeasurePattern(timeSignature: .march, subdivision: .eighth) // 2 beats, 4 steps
        let swing = GrooveFeel(shuffleRatio: 0.60)

        let events = scheduler.scheduleEvents(
            tempo: tempo,
            pattern: pattern,
            grooveFeel: swing,
            numberOfMeasures: 1,
            startingTimeOffset: 1.0
        )

        #expect(events.count == 4)
        // Beat 0: pulse 0 is 0.5 * 0.6 = 0.3s, pulse 1 is 0.5 * 0.4 = 0.2s
        #expect(abs(events[0].timeOffset - 1.0) < 1e-6)
        #expect(abs(events[0].duration - 0.3) < 1e-6)

        #expect(abs(events[1].timeOffset - 1.3) < 1e-6)
        #expect(abs(events[1].duration - 0.2) < 1e-6)

        // Beat 1:
        #expect(abs(events[2].timeOffset - 1.5) < 1e-6)
        #expect(abs(events[2].duration - 0.3) < 1e-6)

        #expect(abs(events[3].timeOffset - 1.8) < 1e-6)
        #expect(abs(events[3].duration - 0.2) < 1e-6)
    }
}
