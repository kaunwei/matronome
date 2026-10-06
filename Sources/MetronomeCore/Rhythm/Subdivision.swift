import Foundation

/// The rhythmic division of a single beat into smaller equal pulses.
public enum Subdivision: String, CaseIterable, Equatable, Hashable, Sendable {
    case quarter
    case eighth
    case triplet
    case sixteenth
    case sextuplet

    /// Number of pulses per beat.
    public var pulsesPerBeat: Int {
        switch self {
        case .quarter: return 1
        case .eighth: return 2
        case .triplet: return 3
        case .sixteenth: return 4
        case .sextuplet: return 6
        }
    }
}
