import SwiftUI
import MetronomeCore

/// Visual row of LED beat lights pulsing dynamically on metronome steps.
public struct BeatLEDsView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    private var totalSteps: Int {
        viewModel.pattern.totalSteps
    }
    
    private var pulsesPerBeat: Int {
        viewModel.subdivision.pulsesPerBeat
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Measure & Beat Counter
            HStack {
                Text("MEASURE \(viewModel.currentMeasureNumber + 1)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("BEAT \(viewModel.currentBeatIndex + 1) / \(viewModel.timeSignature.beatsPerMeasure)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            
            // LED Lights Grid / Row
            HStack(spacing: pulsesPerBeat > 1 ? 4 : 8) {
                ForEach(0..<totalSteps, id: \.self) { stepIndex in
                    let isCurrentStep = (viewModel.playbackState == .playing && viewModel.currentStepIndex == stepIndex)
                    let emphasis = viewModel.pattern[stepIndex]
                    let isBeatStart = (stepIndex % pulsesPerBeat == 0)
                    let beatNumber = (stepIndex / pulsesPerBeat) + 1
                    
                    VStack(spacing: 4) {
                        // LED Bulb
                        ZStack {
                            Circle()
                                .fill(ledColor(for: emphasis, isActive: isCurrentStep))
                                .frame(
                                    width: isBeatStart ? 22 : 14,
                                    height: isBeatStart ? 22 : 14
                                )
                                .shadow(
                                    color: isCurrentStep ? ledColor(for: emphasis, isActive: true).opacity(0.8) : .clear,
                                    radius: isCurrentStep ? 10 : 0
                                )
                                .scaleEffect(isCurrentStep ? 1.25 : 1.0)
                                .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isCurrentStep)
                            
                            if isBeatStart {
                                Text("\(beatNumber)")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(isCurrentStep ? .white : .primary.opacity(0.7))
                            }
                        }
                        
                        // Emphasis Type Dot / Indicator
                        Circle()
                            .fill(emphasisBadgeColor(for: emphasis))
                            .frame(width: 4, height: 4)
                            .opacity(emphasis == .mute ? 0.3 : 0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleStepEmphasis(at: stepIndex)
                    }
                    .help("Step \(stepIndex + 1): \(emphasis.rawValue.capitalized). Tap to toggle emphasis.")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
    
    private func ledColor(for emphasis: BeatEmphasis, isActive: Bool) -> Color {
        if isActive {
            switch emphasis {
            case .downbeat: return Color.red
            case .accent:   return Color.orange
            case .normal:   return Color.accentColor
            case .ghost:    return Color.purple.opacity(0.8)
            case .mute:     return Color.gray.opacity(0.3)
            }
        } else {
            switch emphasis {
            case .downbeat: return Color.red.opacity(0.25)
            case .accent:   return Color.orange.opacity(0.2)
            case .normal:   return Color.accentColor.opacity(0.15)
            case .ghost:    return Color.purple.opacity(0.1)
            case .mute:     return Color.secondary.opacity(0.08)
            }
        }
    }
    
    private func emphasisBadgeColor(for emphasis: BeatEmphasis) -> Color {
        switch emphasis {
        case .downbeat: return Color.red
        case .accent:   return Color.orange
        case .normal:   return Color.accentColor
        case .ghost:    return Color.purple
        case .mute:     return Color.secondary
        }
    }
}
