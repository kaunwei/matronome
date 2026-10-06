import Foundation

/// Pitch modification settings for downbeat / accented clicks.
public struct DownbeatPitch: Equatable, Sendable {
    public var semitoneOffset: Double
    public var frequencyMultiplier: Double {
        return pow(2.0, semitoneOffset / 12.0)
    }

    public init(semitoneOffset: Double = 7.0) {
        self.semitoneOffset = semitoneOffset
    }

    public static let octaveUp = DownbeatPitch(semitoneOffset: 12.0)
    public static let perfectFifth = DownbeatPitch(semitoneOffset: 7.0)
    public static let majorThird = DownbeatPitch(semitoneOffset: 4.0)
    public static let unison = DownbeatPitch(semitoneOffset: 0.0)
}
