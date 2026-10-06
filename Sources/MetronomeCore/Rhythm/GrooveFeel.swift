import Foundation

/// The timing displacement applied to subdivisions to produce swing or shuffle feel (50% straight to 75% hard swing).
public struct GrooveFeel: Equatable, Hashable, Sendable {
    public static let minShuffleRatio: Double = 0.50 // Straight (50% / 50%)
    public static let maxShuffleRatio: Double = 0.75 // Hard swing (75% / 25%, e.g. dotted eighth + sixteenth or hard triplet)
    public static let tripletSwingRatio: Double = 2.0 / 3.0 // Standard triplet swing (66.67%)

    public let shuffleRatio: Double

    public init(shuffleRatio: Double = 0.50) {
        self.shuffleRatio = min(max(shuffleRatio, Self.minShuffleRatio), Self.maxShuffleRatio)
    }

    public static let straight = GrooveFeel(shuffleRatio: 0.50)
    public static let lightSwing = GrooveFeel(shuffleRatio: 0.58)
    public static let standardSwing = GrooveFeel(shuffleRatio: 2.0 / 3.0)
    public static let hardSwing = GrooveFeel(shuffleRatio: 0.75)

    public var isStraight: Bool {
        abs(shuffleRatio - 0.50) < 0.0001
    }
}
