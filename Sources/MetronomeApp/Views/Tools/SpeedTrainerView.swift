import SwiftUI
import MetronomeCore

/// View configuring and controlling the Speed Trainer (gradual tempo acceleration/deceleration).
public struct SpeedTrainerView: View {
    @ObservedObject public var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Enable / Disable Toggle Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Speed Trainer")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Gradually steps tempo every N measures")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $viewModel.isSpeedTrainerActive)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
            
            Divider()
            
            // Configuration Controls
            VStack(spacing: 12) {
                // Start & Target BPM
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Tempo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("\(Int(viewModel.speedTrainerStartBPM))")
                                .font(.system(.title3, design: .monospaced))
                                .bold()
                            Text("BPM")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Slider(
                            value: $viewModel.speedTrainerStartBPM,
                            in: 30...300,
                            step: 1
                        ) {
                            Text("Start BPM")
                        } onEditingChanged: { _ in
                            viewModel.updateSpeedTrainerInEngine()
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Tempo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("\(Int(viewModel.speedTrainerTargetBPM))")
                                .font(.system(.title3, design: .monospaced))
                                .bold()
                            Text("BPM")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Slider(
                            value: $viewModel.speedTrainerTargetBPM,
                            in: 30...300,
                            step: 1
                        ) {
                            Text("Target BPM")
                        } onEditingChanged: { _ in
                            viewModel.updateSpeedTrainerInEngine()
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                }
                
                // Step Amount & Interval Measures
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step Size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("+\(Int(viewModel.speedTrainerStepBPM))")
                                .font(.system(.title3, design: .monospaced))
                                .bold()
                            Text("BPM")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Stepper("", value: $viewModel.speedTrainerStepBPM, in: 1...20, step: 1)
                            .labelsHidden()
                            .onChange(of: viewModel.speedTrainerStepBPM) {
                                viewModel.updateSpeedTrainerInEngine()
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step Every")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("\(viewModel.speedTrainerStepMeasures)")
                                .font(.system(.title3, design: .monospaced))
                                .bold()
                            Text("Bars")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Stepper("", value: $viewModel.speedTrainerStepMeasures, in: 1...32, step: 1)
                            .labelsHidden()
                            .onChange(of: viewModel.speedTrainerStepMeasures) {
                                viewModel.updateSpeedTrainerInEngine()
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                }
                
                // Loop toggle
                Toggle(isOn: $viewModel.speedTrainerLoop) {
                    Text("Loop when target reached (bounce back to start)")
                        .font(.footnote)
                }
                .toggleStyle(CheckboxToggleStyle())
                .onChange(of: viewModel.speedTrainerLoop) {
                    viewModel.updateSpeedTrainerInEngine()
                }
            }
            .opacity(viewModel.isSpeedTrainerActive ? 1.0 : 0.4)
            .disabled(!viewModel.isSpeedTrainerActive)
        }
        .padding(12)
    }
}
