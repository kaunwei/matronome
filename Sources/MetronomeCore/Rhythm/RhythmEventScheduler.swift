import Foundation

/// Represents a single scheduled rhythm event with absolute and relative time offsets.
public struct ScheduledRhythmEvent: Equatable, Sendable {
    public let measureIndex: Int
    public let beatIndex: Int
    public let subdivisionIndex: Int
    public let stepIndexInMeasure: Int
    public let emphasis: BeatEmphasis
    public let timeOffset: TimeInterval
    public let duration: TimeInterval

    public init(
        measureIndex: Int,
        beatIndex: Int,
        subdivisionIndex: Int,
        stepIndexInMeasure: Int,
        emphasis: BeatEmphasis,
        timeOffset: TimeInterval,
        duration: TimeInterval
    ) {
        self.measureIndex = measureIndex
        self.beatIndex = beatIndex
        self.subdivisionIndex = subdivisionIndex
        self.stepIndexInMeasure = stepIndexInMeasure
        self.emphasis = emphasis
        self.timeOffset = timeOffset
        self.duration = duration
    }
}

/// Computes the exact high-precision time offsets for rhythm events taking tempo, time signature, subdivision, and groove feel into account.
public struct RhythmEventScheduler: Sendable {
    public init() {}

    /// Calculates scheduled events for a given number of measures starting at a base time offset.
    public func scheduleEvents(
        tempo: Tempo,
        pattern: MeasurePattern,
        grooveFeel: GrooveFeel = .straight,
        numberOfMeasures: Int = 1,
        startingTimeOffset: TimeInterval = 0.0,
        startingMeasureIndex: Int = 0
    ) -> [ScheduledRhythmEvent] {
        guard numberOfMeasures > 0 else { return [] }

        var events: [ScheduledRhythmEvent] = []
        let beatsPerMeasure = pattern.timeSignature.beatsPerMeasure
        let pulsesPerBeat = pattern.subdivision.pulsesPerBeat
        let beatDuration = tempo.secondsPerBeat
        var currentTime = startingTimeOffset

        for m in 0..<numberOfMeasures {
            let measureIndex = startingMeasureIndex + m
            var stepInMeasure = 0

            for beat in 0..<beatsPerMeasure {
                let intervals = computeSubdivisionIntervals(
                    beatDuration: beatDuration,
                    pulsesPerBeat: pulsesPerBeat,
                    grooveFeel: grooveFeel
                )

                for (subIndex, interval) in intervals.enumerated() {
                    let emphasis = pattern[stepInMeasure]
                    let event = ScheduledRhythmEvent(
                        measureIndex: measureIndex,
                        beatIndex: beat,
                        subdivisionIndex: subIndex,
                        stepIndexInMeasure: stepInMeasure,
                        emphasis: emphasis,
                        timeOffset: currentTime,
                        duration: interval
                    )
                    events.append(event)
                    currentTime += interval
                    stepInMeasure += 1
                }
            }
        }

        return events
    }

    /// Computes the relative durations of each subdivision within a single beat, applying groove shuffle if applicable.
    public func computeSubdivisionIntervals(
        beatDuration: TimeInterval,
        pulsesPerBeat: Int,
        grooveFeel: GrooveFeel
    ) -> [TimeInterval] {
        guard pulsesPerBeat > 1 else {
            return [beatDuration]
        }

        if pulsesPerBeat == 2 {
            // Eighth note pair: apply shuffle ratio directly
            // First eighth = beatDuration * ratio, Second eighth = beatDuration * (1 - ratio)
            let first = beatDuration * grooveFeel.shuffleRatio
            let second = beatDuration * (1.0 - grooveFeel.shuffleRatio)
            return [first, second]
        } else if pulsesPerBeat == 4 {
            // Sixteenth note swing: swing the 1st and 3rd pairs of 16ths
            // Pair 1: 0 & 1, Pair 2: 2 & 3
            let halfBeat = beatDuration / 2.0
            let p1 = halfBeat * grooveFeel.shuffleRatio
            let p2 = halfBeat * (1.0 - grooveFeel.shuffleRatio)
            let p3 = halfBeat * grooveFeel.shuffleRatio
            let p4 = halfBeat * (1.0 - grooveFeel.shuffleRatio)
            return [p1, p2, p3, p4]
        } else {
            // Straight division for triplets, sextuplets, etc.
            let equalInterval = beatDuration / Double(pulsesPerBeat)
            return Array(repeating: equalInterval, count: pulsesPerBeat)
        }
    }
}
