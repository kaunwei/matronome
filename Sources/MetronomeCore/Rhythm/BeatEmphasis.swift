import Foundation

/// The accent level assigned to a specific pulse within a measure.
public enum BeatEmphasis: String, CaseIterable, Equatable, Hashable, Sendable {
    case downbeat
    case accent
    case normal
    case ghost
    case mute

    /// Gain/Volume multiplier for audio playback.
    public var gainMultiplier: Float {
        switch self {
        case .downbeat: return 1.2
        case .accent:   return 1.0
        case .normal:   return 0.7
        case .ghost:    return 0.35
        case .mute:     return 0.0
        }
    }

    /// Whether the emphasis produces audible sound.
    public var isAudible: Bool {
        self != .mute
    }
}
