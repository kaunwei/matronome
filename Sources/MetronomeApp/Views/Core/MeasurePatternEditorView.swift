import SwiftUI
import MetronomeCore

/// Interactive per-beat and per-subdivision pattern editor allowing custom emphasis mapping.
public struct MeasurePatternEditorView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    private var pulsesPerBeat: Int {
        viewModel.subdivision.pulsesPerBeat
    }
    
    private var beatsCount: Int {
        viewModel.timeSignature.beatsPerMeasure
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Presets / Action Tools
            HStack {
                Label("Measure Pattern Editor", systemImage: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .bold))
                
                Spacer()
                
                Menu {
                    Button("Reset to Default Pattern") {
                        viewModel.resetPatternToDefault()
                    }
                    Button("All Normal Beats") {
                        viewModel.setAllStepsEmphasis(.normal)
                    }
                    Button("Downbeat Beat 1, Normal Rest") {
                        setFirstDownbeatRestNormal()
                    }
                    Button("Accent All Beats, Ghost Subdivisions") {
                        setAccentsOnBeats()
                    }
                    Button("Mute Subdivisions") {
                        muteSubdivisions()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("Presets")
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 85)
            }
            
            // Steps Grid grouped by Beat
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<beatsCount, id: \.self) { beatIndex in
                        beatColumnView(beatIndex: beatIndex)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Emphasis Legend
            HStack(spacing: 12) {
                legendItem(emphasis: .downbeat, label: "Downbeat (120%)")
                legendItem(emphasis: .accent, label: "Accent (100%)")
                legendItem(emphasis: .normal, label: "Normal (70%)")
                legendItem(emphasis: .ghost, label: "Ghost (35%)")
                legendItem(emphasis: .mute, label: "Mute (0%)")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Beat Column View
    private func beatColumnView(beatIndex: Int) -> some View {
        VStack(spacing: 6) {
            Text("BEAT \(beatIndex + 1)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(0..<pulsesPerBeat, id: \.self) { subIndex in
                    let stepIndex = beatIndex * pulsesPerBeat + subIndex
                    if stepIndex < viewModel.pattern.steps.count {
                        stepTileView(stepIndex: stepIndex, subIndex: subIndex)
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
    }
    
    // MARK: - Individual Step Tile
    private func stepTileView(stepIndex: Int, subIndex: Int) -> some View {
        let emphasis = viewModel.pattern[stepIndex]
        let isCurrent = (viewModel.playbackState == .playing && viewModel.currentStepIndex == stepIndex)
        
        return Button(action: {
            viewModel.toggleStepEmphasis(at: stepIndex)
        }) {
            VStack(spacing: 4) {
                // Emphasis Icon
                Image(systemName: iconName(for: emphasis))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(emphasisColor(for: emphasis))
                
                // Emphasis text tag
                Text(shortName(for: emphasis))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(emphasisColor(for: emphasis))
            }
            .frame(width: pulsesPerBeat == 1 ? 48 : 36, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isCurrent ? emphasisColor(for: emphasis).opacity(0.25) : emphasisColor(for: emphasis).opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(
                        isCurrent ? emphasisColor(for: emphasis) : Color.secondary.opacity(0.2),
                        lineWidth: isCurrent ? 2 : 1
                    )
            )
            .shadow(color: isCurrent ? emphasisColor(for: emphasis).opacity(0.5) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(BeatEmphasis.allCases, id: \.self) { option in
                Button(action: {
                    viewModel.setStepEmphasis(option, at: stepIndex)
                }) {
                    HStack {
                        Image(systemName: iconName(for: option))
                        Text(option.rawValue.capitalized)
                    }
                }
            }
        }
        .help("Step \(stepIndex + 1): \(emphasis.rawValue.capitalized). Click to cycle.")
    }
    
    // MARK: - Helpers
    private func legendItem(emphasis: BeatEmphasis, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(emphasisColor(for: emphasis))
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
    
    private func iconName(for emphasis: BeatEmphasis) -> String {
        switch emphasis {
        case .downbeat: return "flame.fill"
        case .accent:   return "bolt.fill"
        case .normal:   return "circle.fill"
        case .ghost:    return "circle.dotted"
        case .mute:     return "speaker.slash.fill"
        }
    }
    
    private func shortName(for emphasis: BeatEmphasis) -> String {
        switch emphasis {
        case .downbeat: return "DOWN"
        case .accent:   return "ACC"
        case .normal:   return "NORM"
        case .ghost:    return "GST"
        case .mute:     return "MUTE"
        }
    }
    
    private func emphasisColor(for emphasis: BeatEmphasis) -> Color {
        switch emphasis {
        case .downbeat: return Color.red
        case .accent:   return Color.orange
        case .normal:   return Color.accentColor
        case .ghost:    return Color.purple
        case .mute:     return Color.secondary
        }
    }
    
    // MARK: - Pattern Customizers
    private func setFirstDownbeatRestNormal() {
        var steps = Array(repeating: BeatEmphasis.normal, count: viewModel.pattern.totalSteps)
        if !steps.isEmpty {
            steps[0] = .downbeat
        }
        viewModel.pattern = MeasurePattern(
            timeSignature: viewModel.timeSignature,
            subdivision: viewModel.subdivision,
            steps: steps
        )
    }
    
    private func setAccentsOnBeats() {
        var steps: [BeatEmphasis] = []
        let pulses = viewModel.subdivision.pulsesPerBeat
        for i in 0..<viewModel.pattern.totalSteps {
            if i == 0 {
                steps.append(.downbeat)
            } else if i % pulses == 0 {
                steps.append(.accent)
            } else {
                steps.append(.ghost)
            }
        }
        viewModel.pattern = MeasurePattern(
            timeSignature: viewModel.timeSignature,
            subdivision: viewModel.subdivision,
            steps: steps
        )
    }
    
    private func muteSubdivisions() {
        var steps = viewModel.pattern.steps
        let pulses = viewModel.subdivision.pulsesPerBeat
        for i in 0..<steps.count {
            if i % pulses != 0 {
                steps[i] = .mute
            }
        }
        viewModel.pattern = MeasurePattern(
            timeSignature: viewModel.timeSignature,
            subdivision: viewModel.subdivision,
            steps: steps
        )
    }
}
