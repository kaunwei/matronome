import SwiftUI
import MetronomeCore

/// Main SwiftUI Metronome view assembling all interactive visualizers, tempo controls, rhythm settings, and preset slots.
@MainActor
public struct MainMetronomeView: View {
    @StateObject private var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? MetronomeViewModel())
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Practice Time & Status Header (Session, Weekly Reset, Target Countdown)
                PracticeTimeHeader(viewModel: viewModel)
                
                // 2. Dynamic 2-Column Preset Slots Bar (Hotkeys 1-9, Elongated Cards, Scrollable)
                PresetSlotsBar(viewModel: viewModel)
                
                // 3. High-Visibility Beat LEDs Indicator
                BeatLEDsView(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    )
                
                // 4. Integrated Tempo & Transport Centerpiece (BPM + Start/Pause + Tap)
                BPMDialView(viewModel: viewModel)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    )
                
                // 5. Rhythm Settings (Customizable Time Signature, Subdivision, Groove/Shuffle)
                RhythmSettingsView(viewModel: viewModel)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    )
                
                // 6. Interactive Measure Pattern Editor (Per-beat toggle downbeat/accent/mute)
                MeasurePatternEditorView(viewModel: viewModel)
                
                // 7. Collapsible Pro Tools Drawer (Speed Trainer, Gap Trainer, Practice Stats)
                ProToolsDrawerView(viewModel: viewModel)
                
                // 8. Sound & Pitch Settings Button
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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding(20)
            .frame(minWidth: 520, maxWidth: 660)
        }
        .frame(minWidth: 540, minHeight: 720)
        .background(Color(nsColor: .underPageBackgroundColor).opacity(0.5))
        .sheet(isPresented: $viewModel.isSoundSettingsPresented) {
            SoundSettingsSheetView(viewModel: viewModel)
        }
    }
}
