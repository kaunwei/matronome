import SwiftUI
import MetronomeCore

/// Rhythm parameter settings: Time Signature, Subdivision, Groove/Shuffle feel, and Sound Timbre.
public struct RhythmSettingsView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    // Preset time signatures
    private let commonTimeSignatures: [TimeSignature] = [
        TimeSignature(beatsPerMeasure: 2, beatValue: 4),
        TimeSignature(beatsPerMeasure: 3, beatValue: 4),
        TimeSignature(beatsPerMeasure: 4, beatValue: 4),
        TimeSignature(beatsPerMeasure: 5, beatValue: 4),
        TimeSignature(beatsPerMeasure: 6, beatValue: 8),
        TimeSignature(beatsPerMeasure: 7, beatValue: 8),
        TimeSignature(beatsPerMeasure: 9, beatValue: 8),
        TimeSignature(beatsPerMeasure: 12, beatValue: 8)
    ]
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Time Signature & Subdivision Row
            HStack(alignment: .top, spacing: 16) {
                // Time Signature Card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Time Signature", systemImage: "metronome")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(commonTimeSignatures, id: \.self) { ts in
                                let isSelected = (viewModel.timeSignature == ts)
                                Button(action: {
                                    viewModel.timeSignature = ts
                                }) {
                                    Text(ts.description)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                                        )
                                        .foregroundColor(isSelected ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Subdivision Card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Subdivision", systemImage: "music.note")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        ForEach(Subdivision.allCases, id: \.self) { sub in
                            let isSelected = (viewModel.subdivision == sub)
                            Button(action: {
                                viewModel.subdivision = sub
                            }) {
                                VStack(spacing: 2) {
                                    Text(subdivisionSymbol(sub))
                                        .font(.system(size: 13, weight: .bold))
                                    Text(subdivisionName(sub))
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                                )
                                .foregroundColor(isSelected ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Groove & Shuffle Controls + Audio Settings Row
            HStack(spacing: 16) {
                // Shuffle / Groove Feel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Shuffle & Groove", systemImage: "waveform.path")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.grooveFeel.shuffleRatio * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                    
                    HStack(spacing: 6) {
                        groovePresetButton(name: "Straight", ratio: 0.50)
                        groovePresetButton(name: "Light (58%)", ratio: 0.58)
                        groovePresetButton(name: "Triplet (66%)", ratio: 2.0 / 3.0)
                        groovePresetButton(name: "Hard (75%)", ratio: 0.75)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.grooveFeel.shuffleRatio },
                            set: { viewModel.setGrooveShuffleRatio($0) }
                        ),
                        in: 0.50...0.75,
                        step: 0.01
                    )
                    .accentColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                )
                
                // Sound Timbre & Volume
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Sound Timbre", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: $viewModel.timbre) {
                            ForEach(Timbre.allCases, id: \.self) { timbre in
                                Text(timbre.displayName).tag(timbre)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.toggleMute()
                        }) {
                            Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .foregroundColor(viewModel.isMuted ? .red : .secondary)
                                .frame(width: 20)
                        }
                        .buttonStyle(.plain)
                        
                        Slider(
                            value: $viewModel.volume,
                            in: 0.0...1.0,
                            step: 0.05
                        )
                        .accentColor(.accentColor)
                        
                        Text("\(Int(viewModel.volume * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                )
            }
        }
    }
    
    private func groovePresetButton(name: String, ratio: Double) -> some View {
        let isSelected = abs(viewModel.grooveFeel.shuffleRatio - ratio) < 0.01
        return Button(action: {
            viewModel.setGrooveShuffleRatio(ratio)
        }) {
            Text(name)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    private func subdivisionSymbol(_ sub: Subdivision) -> String {
        switch sub {
        case .quarter: return "♩"
        case .eighth: return "♪"
        case .triplet: return "3"
        case .sixteenth: return "♬"
        case .sextuplet: return "6"
        }
    }
    
    private func subdivisionName(_ sub: Subdivision) -> String {
        switch sub {
        case .quarter: return "1/4"
        case .eighth: return "1/8"
        case .triplet: return "1/3"
        case .sixteenth: return "1/16"
        case .sextuplet: return "1/24"
        }
    }
}
