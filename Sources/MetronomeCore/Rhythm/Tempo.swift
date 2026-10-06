import Foundation

/// Represents the tempo of a rhythm measured strictly in Beats Per Minute (BPM, 20 to 400).
public struct Tempo: Equatable, Hashable, Sendable, Comparable {
    public static let minBPM: Double = 20.0
    public static let maxBPM: Double = 400.0
    public static let defaultBPM: Double = 120.0

    public let bpm: Double

    public init(bpm: Double = defaultBPM) {
        self.bpm = min(max(bpm, Self.minBPM), Self.maxBPM)
    }

    public static func < (lhs: Tempo, rhs: Tempo) -> Bool {
        lhs.bpm < rhs.bpm
    }

    /// Duration of a single quarter note in seconds.
    public var secondsPerBeat: TimeInterval {
        60.0 / bpm
    }
}

/// Helper to calculate BPM from consecutive user tap timestamps.
public struct TapTempoCalculator: Sendable {
    private var tapTimestamps: [TimeInterval] = []
    private let maxTapHistory: Int
    private let timeoutInterval: TimeInterval

    public init(maxTapHistory: Int = 8, timeoutInterval: TimeInterval = 2.5) {
        self.maxTapHistory = max(2, maxTapHistory)
        self.timeoutInterval = timeoutInterval
    }

    public mutating func reset() {
        tapTimestamps.removeAll()
    }

    /// Records a tap timestamp and returns the newly calculated Tempo, or nil if insufficient taps.
    @discardableResult
    public mutating func tap(at timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Tempo? {
        if let last = tapTimestamps.last, (timestamp - last) > timeoutInterval {
            tapTimestamps.removeAll()
        }

        tapTimestamps.append(timestamp)
        if tapTimestamps.count > maxTapHistory {
            tapTimestamps.removeFirst(tapTimestamps.count - maxTapHistory)
        }

        guard tapTimestamps.count >= 2 else {
            return nil
        }

        var totalInterval: TimeInterval = 0.0
        for i in 1..<tapTimestamps.count {
            totalInterval += (tapTimestamps[i] - tapTimestamps[i - 1])
        }

        let averageInterval = totalInterval / Double(tapTimestamps.count - 1)
        guard averageInterval > 0 else { return nil }

        let calculatedBPM = 60.0 / averageInterval
        return Tempo(bpm: calculatedBPM.rounded())
    }
}
