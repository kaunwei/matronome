import Foundation

/// Represents the meter definition consisting of beats per measure (numerator) and the reference beat unit (denominator).
public struct TimeSignature: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let beatsPerMeasure: Int
    public let beatValue: Int

    public init(beatsPerMeasure: Int = 4, beatValue: Int = 4) {
        self.beatsPerMeasure = max(1, beatsPerMeasure)
        self.beatValue = (beatValue > 0 && (beatValue & (beatValue - 1)) == 0) ? beatValue : 4
    }

    public var description: String {
        "\(beatsPerMeasure)/\(beatValue)"
    }

    public static let common = TimeSignature(beatsPerMeasure: 4, beatValue: 4)
    public static let waltz = TimeSignature(beatsPerMeasure: 3, beatValue: 4)
    public static let march = TimeSignature(beatsPerMeasure: 2, beatValue: 4)
    public static let sixEight = TimeSignature(beatsPerMeasure: 6, beatValue: 8)
    public static let sevenEight = TimeSignature(beatsPerMeasure: 7, beatValue: 8)
}
