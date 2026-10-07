import Foundation

/// Defines the per-pulse emphasis structure of a single measure.
public struct MeasurePattern: Codable, Equatable, Hashable, Sendable {
    public let timeSignature: TimeSignature
    public let subdivision: Subdivision
    public var steps: [BeatEmphasis]

    public var totalSteps: Int {
        timeSignature.beatsPerMeasure * subdivision.pulsesPerBeat
    }

    public init(timeSignature: TimeSignature = .common, subdivision: Subdivision = .quarter, steps: [BeatEmphasis]? = nil) {
        self.timeSignature = timeSignature
        self.subdivision = subdivision

        let expectedCount = timeSignature.beatsPerMeasure * subdivision.pulsesPerBeat

        if let providedSteps = steps, providedSteps.count == expectedCount {
            self.steps = providedSteps
        } else {
            // Default pattern generation: downbeat on step 0, normal on beat starts, ghost on subdivisions
            var defaultSteps: [BeatEmphasis] = []
            defaultSteps.reserveCapacity(expectedCount)
            let pulses = subdivision.pulsesPerBeat

            for i in 0..<expectedCount {
                if i == 0 {
                    defaultSteps.append(.downbeat)
                } else if i % pulses == 0 {
                    defaultSteps.append(.normal)
                } else {
                    defaultSteps.append(.ghost)
                }
            }
            self.steps = defaultSteps
        }
    }

    public subscript(index: Int) -> BeatEmphasis {
        get {
            guard !steps.isEmpty else { return .normal }
            let wrappedIndex = ((index % steps.count) + steps.count) % steps.count
            return steps[wrappedIndex]
        }
        set {
            guard !steps.isEmpty else { return }
            let wrappedIndex = ((index % steps.count) + steps.count) % steps.count
            steps[wrappedIndex] = newValue
        }
    }
}
