import SwiftUI
import MetronomeCore

/// Settings sheet for audio timbre selection, downbeat pitch frequency/semitone tuning, and volume.
public struct SoundSettingsSheetView: View {
    @ObservedObject public var viewModel: MetronomeViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    private let downbeatIntervals: [(name: String, semitones: Double)] = [
        ("Unison (0 st)", 0.0),
        ("Minor 3rd (+3 st)", 3.0),
        ("Major 3rd (+4 st)", 4.0),
        ("Perfect 4th (+5 st)", 5.0),
        ("Perfect 5th (+7 st)", 7.0),
        ("Octave (+12 st)", 12.0),
        ("Octave + 5th (+19 st)", 19.0)
    ]
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                    Text("Sound & Pitch Settings")
                        .font(.title3.bold())
                }
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Timbre Selector Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CLICK TIMBRE")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(Timbre.allCases, id: \.self) { timbreOption in
                                Button(action: {
                                    viewModel.timbre = timbreOption
                                }) {
                                    HStack {
                                        Image(systemName: timbreIcon(for: timbreOption))
                                            .foregroundColor(viewModel.timbre == timbreOption ? .white : .accentColor)
                                        Text(timbreOption.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(viewModel.timbre == timbreOption ? .white : .primary)
                                        Spacer()
                                        if viewModel.timbre == timbreOption {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        viewModel.timbre == timbreOption
                                            ? Color.accentColor
                                            : Color(nsColor: .controlBackgroundColor).opacity(0.6)
                                    )
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Downbeat Pitch Frequency / Semitone Slider
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DOWNBEAT PITCH ACCENT")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                Text("Pitch offset applied to the first beat of each measure")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(String(format: "+%.1f semitones", viewModel.downbeatPitchSemitones))
                                .font(.system(.subheadline, design: .monospaced))
                                .bold()
                                .foregroundColor(.accentColor)
                        }
                        
                        Slider(
                            value: $viewModel.downbeatPitchSemitones,
                            in: 0.0...24.0,
                            step: 0.5
                        ) {
                            Text("Downbeat Pitch")
                        }
                        
                        // Interval Shortcut Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(downbeatIntervals, id: \.name) { interval in
                                    Button(action: {
                                        viewModel.downbeatPitchSemitones = interval.semitones
                                    }) {
                                        Text(interval.name)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(
                                                abs(viewModel.downbeatPitchSemitones - interval.semitones) < 0.1
                                                    ? Color.accentColor.opacity(0.2)
                                                    : Color(nsColor: .controlBackgroundColor).opacity(0.5)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(
                                                        abs(viewModel.downbeatPitchSemitones - interval.semitones) < 0.1
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
                    }
                    
                    Divider()
                    
                    // Master Volume Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("MASTER CLICK VOLUME")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(viewModel.volume * 100))%")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.secondary)
                            Slider(value: $viewModel.volume, in: 0.0...1.0)
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 460, minHeight: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func timbreIcon(for timbre: Timbre) -> String {
        switch timbre {
        case .woodblock: return "leaf.fill"
        case .digitalBeep: return "waveform.path"
        case .studioClick: return "metronome.fill"
        case .rimshot: return "circle.grid.cross.fill"
        case .sineSynth: return "waveform"
        }
    }
}
