import Foundation

/// Defines how the speed trainer adjusts tempo over time/measures.
public struct SpeedTrainerConfig: Equatable, Hashable, Sendable {
    public let startBPM: Double
    public let targetBPM: Double
    public let stepBPM: Double
    public let stepIntervalMeasures: Int
    public let loopOnComplete: Bool

    public init(
        startBPM: Double = 100.0,
        targetBPM: Double = 160.0,
        stepBPM: Double = 5.0,
        stepIntervalMeasures: Int = 4,
        loopOnComplete: Bool = false
    ) {
        self.startBPM = min(max(startBPM, Tempo.minBPM), Tempo.maxBPM)
        self.targetBPM = min(max(targetBPM, Tempo.minBPM), Tempo.maxBPM)
        self.stepBPM = max(1.0, abs(stepBPM))
        self.stepIntervalMeasures = max(1, stepIntervalMeasures)
        self.loopOnComplete = loopOnComplete
    }

    /// Whether this speed trainer accelerates (speed increases) or decelerates (speed decreases).
    public var isAccelerating: Bool {
        targetBPM >= startBPM
    }
}

/// Pure algorithmic state machine that manages tempo changes every N measures.
public struct SpeedTrainer: Sendable {
    public let config: SpeedTrainerConfig
    public private(set) var currentBPM: Double
    public private(set) var completedMeasures: Int = 0
    public private(set) var isCompleted: Bool = false

    public init(config: SpeedTrainerConfig) {
        self.config = config
        self.currentBPM = config.startBPM
        self.completedMeasures = 0
        self.isCompleted = (config.startBPM == config.targetBPM)
    }

    /// Current tempo value wrapped in Tempo struct.
    public var currentTempo: Tempo {
        Tempo(bpm: currentBPM)
    }

    /// Resets the trainer back to starting condition.
    public mutating func reset() {
        self.currentBPM = config.startBPM
        self.completedMeasures = 0
        self.isCompleted = (config.startBPM == config.targetBPM)
    }

    /// Advances measure count by 1 and updates currentBPM if step boundary reached.
    /// Returns the updated current Tempo.
    @discardableResult
    public mutating func advanceMeasure() -> Tempo {
        if isCompleted {
            if config.loopOnComplete {
                reset()
                // After reset on loop, advance the 1st measure of the new cycle
                completedMeasures += 1
                return currentTempo
            } else {
                return currentTempo
            }
        }

        completedMeasures += 1

        if completedMeasures % config.stepIntervalMeasures == 0 {
            if config.isAccelerating {
                let nextBPM = currentBPM + config.stepBPM
                if nextBPM >= config.targetBPM {
                    currentBPM = config.targetBPM
                    isCompleted = true
                } else {
                    currentBPM = nextBPM
                }
            } else {
                let nextBPM = currentBPM - config.stepBPM
                if nextBPM <= config.targetBPM {
                    currentBPM = config.targetBPM
                    isCompleted = true
                } else {
                    currentBPM = nextBPM
                }
            }
        }

        return currentTempo
    }
}
