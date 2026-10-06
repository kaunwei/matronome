import SwiftUI
import MetronomeCore

/// View configuring Gap Trainer (sound bars vs silent bars, or random silence probability).
public struct GapTrainerView: View {
    @ObservedObject public var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gap Trainer")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Develop internal clock by periodically muting bars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $viewModel.isGapTrainerActive)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
            
            Divider()
            
            // Mode Selector: Fixed Measure Pattern vs Random Gap
            Picker("Mode", selection: $viewModel.gapTrainerModeIndex) {
                Text("Bar Pattern").tag(0)
                Text("Random Gaps").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.gapTrainerModeIndex) {
                viewModel.updateGapTrainerInEngine()
            }
            
            if viewModel.gapTrainerModeIndex == 0 {
                // Fixed Sound Bars / Silent Bars Pattern
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sound Bars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.green)
                            Text("\(viewModel.gapTrainerSoundBars)")
                                .font(.system(.title3, design: .monospaced))
                                .bold()
                            Text("bars")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Stepper("", value: $viewModel.gapTrainerSoundBars, in: 1...16, step: 1)
                            .labelsHidden()
                            .onChange(of: viewModel.gapTrainerSoundBars) {
                                viewModel.updateGapTrainerInEngine()
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Silent Bars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "speaker.slash.fill")
                                .foregroundColor(.orange)
                            Text("\(viewModel.gapTrainerSilentBars)")
                                .font(.system(.title3, design: .monospaced))
                                .bold()
                            Text("bars")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Stepper("", value: $viewModel.gapTrainerSilentBars, in: 1...16, step: 1)
                            .labelsHidden()
                            .onChange(of: viewModel.gapTrainerSilentBars) {
                                viewModel.updateGapTrainerInEngine()
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                }
            } else {
                // Random Gap Probability Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Mute Probability")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(viewModel.gapTrainerMuteProbability * 100))%")
                            .font(.system(.body, design: .monospaced))
                            .bold()
                    }
                    Slider(value: $viewModel.gapTrainerMuteProbability, in: 0.05...0.95, step: 0.05) {
                        Text("Probability")
                    } onEditingChanged: { _ in
                        viewModel.updateGapTrainerInEngine()
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
            }
        }
        .padding(12)
        .opacity(viewModel.isGapTrainerActive ? 1.0 : 0.4)
        .disabled(!viewModel.isGapTrainerActive)
    }
}
