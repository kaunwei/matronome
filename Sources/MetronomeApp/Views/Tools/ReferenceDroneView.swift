import SwiftUI
import MetronomeCore

/// View controlling continuous pure sine Reference Drone Tuner (A440 - A442 standard pitches & micro-tuning).
public struct ReferenceDroneView: View {
    @ObservedObject public var viewModel: MetronomeViewModel
    
    // Quick frequency presets
    private let tuningPresets: [(name: String, freq: Double)] = [
        ("A440 (Concert)", 440.0),
        ("A442 (Orchestral)", 442.0),
        ("A444 (Baroque High)", 444.0),
        ("A415 (Baroque Low)", 415.3),
        ("C523.25 (C5)", 523.25),
        ("E329.63 (Guitar E)", 329.63)
    ]
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Play/Stop Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reference Drone Tuner")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Continuous sine wave for pitch intonation & ear training")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    viewModel.toggleDrone()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isDronePlaying ? "stop.fill" : "play.fill")
                        Text(viewModel.isDronePlaying ? "Stop Drone" : "Start Drone")
                    }
                    .font(.callout.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.isDronePlaying ? Color.red.opacity(0.85) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            // Frequency Display & Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pitch Frequency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f Hz", viewModel.droneFrequency))
                        .font(.system(.title3, design: .monospaced))
                        .bold()
                        .foregroundColor(.accentColor)
                }
                
                Slider(
                    value: $viewModel.droneFrequency,
                    in: 200...800,
                    step: 0.5
                ) {
                    Text("Frequency")
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            
            // Preset Buttons
            VStack(alignment: .leading, spacing: 6) {
                Text("Standard Tuning Standards")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(tuningPresets, id: \.name) { preset in
                        Button(action: {
                            viewModel.setDronePitch(frequency: preset.freq)
                        }) {
                            HStack {
                                Text(preset.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "%.1f", preset.freq))
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                abs(viewModel.droneFrequency - preset.freq) < 0.1
                                    ? Color.accentColor.opacity(0.2)
                                    : Color(nsColor: .controlBackgroundColor).opacity(0.5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        abs(viewModel.droneFrequency - preset.freq) < 0.1
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Drone Volume Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Drone Volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.droneVolume * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: $viewModel.droneVolume, in: 0...1.0)
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
        .padding(12)
    }
}
