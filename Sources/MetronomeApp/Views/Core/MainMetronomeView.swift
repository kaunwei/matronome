import SwiftUI
import MetronomeCore

/// Main SwiftUI Metronome view assembling all interactive visualizers and rhythm controls.
@MainActor
public struct MainMetronomeView: View {
    @StateObject private var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? MetronomeViewModel())
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Practice Time & Status Header (with collapsible Target Countdown Timer)
                PracticeTimeHeader(viewModel: viewModel)
                
                // Dynamic Preset Slots Bar (Hotkeys 1-9, snapshot recall & management)
                PresetSlotsBar(viewModel: viewModel)
                
                // Visualizer Section (Pendulum & Beat LEDs)
                VStack(spacing: 12) {
                    PendulumVisualizerView(viewModel: viewModel)
                    BeatLEDsView(viewModel: viewModel)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
                
                // BPM Dial & Stepper
                BPMDialView(viewModel: viewModel)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    )
                
                // Transport Controls (Play / Stop / Tap Tempo)
                TransportControlView(viewModel: viewModel)
                
                // Rhythm Settings (Time Signature, Subdivision, Shuffle, Timbre)
                RhythmSettingsView(viewModel: viewModel)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    )
                
                // Interactive Measure Pattern Editor
                MeasurePatternEditorView(viewModel: viewModel)
                
                // Collapsible Pro Tools Drawer (Speed Trainer, Gap Trainer, Drone Tuner, Stats)
                ProToolsDrawerView(viewModel: viewModel)
                
                // Sound Settings Button
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.isSoundSettingsPresented = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Sound & Pitch Settings")
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(minWidth: 520, maxWidth: 680)
        }
        .frame(minWidth: 540, minHeight: 700)
        .background(Color(nsColor: .underPageBackgroundColor).opacity(0.5))
        .sheet(isPresented: $viewModel.isSoundSettingsPresented) {
            SoundSettingsSheetView(viewModel: viewModel)
        }
    }
}

private extension MetronomePlaybackState {
    var statusText: String {
        switch self {
        case .playing: return "PLAYING"
        case .paused:  return "PAUSED"
        case .stopped: return "STOPPED"
        }
    }
}
