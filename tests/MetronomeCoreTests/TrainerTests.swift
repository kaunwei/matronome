import Testing
import Foundation
@testable import MetronomeCore

final class DeterministicRandomBox: @unchecked Sendable {
    var value: Double
    init(value: Double) {
        self.value = value
    }
}

@Suite struct TrainerTests {
    // MARK: - SpeedTrainer Tests

    @Test func testSpeedTrainerAcceleration() {
        let config = SpeedTrainerConfig(
            startBPM: 100.0,
            targetBPM: 110.0,
            stepBPM: 5.0,
            stepIntervalMeasures: 2,
            loopOnComplete: false
        )
        var trainer = SpeedTrainer(config: config)

        #expect(trainer.currentBPM == 100.0)
        #expect(!trainer.isCompleted)

        // Measure 1
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 100.0)
        #expect(!trainer.isCompleted)

        // Measure 2 (step interval reached: +5 -> 105)
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 105.0)
        #expect(!trainer.isCompleted)

        // Measure 3
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 105.0)
        #expect(!trainer.isCompleted)

        // Measure 4 (step interval reached: +5 -> 110 == target)
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 110.0)
        #expect(trainer.isCompleted)

        // Further measures without loop should remain completed and clamped at target
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 110.0)
        #expect(trainer.isCompleted)
    }

    @Test func testSpeedTrainerDeceleration() {
        let config = SpeedTrainerConfig(
            startBPM: 120.0,
            targetBPM: 100.0,
            stepBPM: 10.0,
            stepIntervalMeasures: 1,
            loopOnComplete: false
        )
        var trainer = SpeedTrainer(config: config)

        #expect(!trainer.config.isAccelerating)
        #expect(trainer.currentBPM == 120.0)

        // Measure 1 -> 110
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 110.0)
        #expect(!trainer.isCompleted)

        // Measure 2 -> 100 (target reached)
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 100.0)
        #expect(trainer.isCompleted)
    }

    @Test func testSpeedTrainerLoopAndReset() {
        let config = SpeedTrainerConfig(
            startBPM: 60.0,
            targetBPM: 70.0,
            stepBPM: 10.0,
            stepIntervalMeasures: 2,
            loopOnComplete: true
        )
        var trainer = SpeedTrainer(config: config)

        // Advance 2 measures to complete (+10 -> 70)
        trainer.advanceMeasure()
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 70.0)
        #expect(trainer.isCompleted)

        // Advance again triggers loop reset
        trainer.advanceMeasure()
        #expect(trainer.currentBPM == 60.0)
        #expect(!trainer.isCompleted)

        // Manual reset
        trainer.reset()
        #expect(trainer.currentBPM == 60.0)
        #expect(trainer.completedMeasures == 0)
    }

    // MARK: - GapTrainer Tests

    @Test func testGapTrainerBarPattern() {
        // 3 bars sound, 1 bar silent
        var trainer = GapTrainer(mode: .barPattern(soundBars: 3, silentBars: 1))

        // Measure 0: Sound (index 0)
        #expect(!trainer.isMuted())

        // Measure 1: Sound (index 1)
        trainer.advanceMeasure()
        #expect(!trainer.isMuted())

        // Measure 2: Sound (index 2)
        trainer.advanceMeasure()
        #expect(!trainer.isMuted())

        // Measure 3: Silent (index 3)
        trainer.advanceMeasure()
        #expect(trainer.isMuted())

        // Measure 4: Sound again (index 4 % 4 == 0)
        trainer.advanceMeasure()
        #expect(!trainer.isMuted())

        // Test reset
        trainer.reset()
        #expect(trainer.measureIndex == 0)
        #expect(!trainer.isMuted())
    }

    @Test func testGapTrainerRandomGapDeterministic() {
        let box = DeterministicRandomBox(value: 0.2)
        var trainer = GapTrainer(
            mode: .randomGap(muteProbability: 0.5),
            randomDoubleGenerator: { box.value }
        )

        // roll 0.2 < 0.5 -> muted
        #expect(trainer.isMuted())

        // change roll to 0.8 >= 0.5 -> not muted
        box.value = 0.8
        #expect(!trainer.isMuted())

        // Advance measure increments counter
        trainer.advanceMeasure()
        #expect(trainer.measureIndex == 1)
    }

    @Test func testGapTrainerBoundaryConditions() {
        let alwaysMuted = GapTrainer(mode: .randomGap(muteProbability: 1.0))
        #expect(alwaysMuted.isMuted())

        let neverMuted = GapTrainer(mode: .randomGap(muteProbability: 0.0))
        #expect(!neverMuted.isMuted())
    }
}
