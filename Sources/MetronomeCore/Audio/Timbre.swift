import Foundation

/// Defines available synthesizer timbres for click generation.
public enum Timbre: String, CaseIterable, Sendable {
    case woodblock
    case digitalBeep
    case studioClick
    case rimshot
    case sineSynth

    public var displayName: String {
        switch self {
        case .woodblock: return "Woodblock"
        case .digitalBeep: return "Digital Beep"
        case .studioClick: return "Studio Click"
        case .rimshot: return "Rimshot"
        case .sineSynth: return "Sine Synth"
        }
    }
}
