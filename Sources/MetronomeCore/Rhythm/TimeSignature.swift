import Foundation

/// Represents the meter definition consisting of beats per measure (numerator) and the reference beat unit (denominator).
/// Supports arbitrary custom time signatures (e.g. 4/4, 3/3, 5/8, 7/4, 11/16).
public struct TimeSignature: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let beatsPerMeasure: Int
    public let beatValue: Int

    public init(beatsPerMeasure: Int = 4, beatValue: Int = 4) {
        self.beatsPerMeasure = max(1, min(64, beatsPerMeasure))
        self.beatValue = max(1, min(64, beatValue))
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
