import Foundation

/// Defines mode and settings for GapTrainer (sound vs silence).
public enum GapTrainerMode: Equatable, Hashable, Sendable {
    /// Fixed measure sequence: sound for `soundBars`, silent for `silentBars`.
    case barPattern(soundBars: Int, silentBars: Int)
    /// Random gap probability per measure or beat: muteProbability from 0.0 to 1.0.
    case randomGap(muteProbability: Double)
}

/// Pure algorithmic state machine for gap trainer (mutes audio according to pattern or probability).
public struct GapTrainer: Sendable {
    public let mode: GapTrainerMode
    public private(set) var measureIndex: Int = 0

    // Random generator closure for deterministic unit testing
    private let randomDoubleGenerator: @Sendable () -> Double

    public init(
        mode: GapTrainerMode = .barPattern(soundBars: 3, silentBars: 1),
        randomDoubleGenerator: (@Sendable () -> Double)? = nil
    ) {
        self.mode = mode
        self.measureIndex = 0
        self.randomDoubleGenerator = randomDoubleGenerator ?? { Double.random(in: 0.0...1.0) }
    }

    /// Resets the gap trainer state.
    public mutating func reset() {
        measureIndex = 0
    }

    /// Evaluates whether the current measure should be muted.
    public func isMuted() -> Bool {
        switch mode {
        case .barPattern(let soundBars, let silentBars):
            let sBars = max(1, soundBars)
            let mBars = max(1, silentBars)
            let cycleLength = sBars + mBars
            let posInCycle = measureIndex % cycleLength
            return posInCycle >= sBars

        case .randomGap(let muteProbability):
            let prob = min(max(muteProbability, 0.0), 1.0)
            if prob <= 0.0 { return false }
            if prob >= 1.0 { return true }
            let roll = randomDoubleGenerator()
            return roll < prob
        }
    }

    /// Advances measure count by 1 and returns whether the new measure is muted.
    @discardableResult
    public mutating func advanceMeasure() -> Bool {
        measureIndex += 1
        return isMuted()
    }
}
