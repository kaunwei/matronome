import SwiftUI
import MetronomeCore

/// Rhythm parameter settings: Customizable Time Signature (custom numerator/denominator), Subdivision, and Groove/Shuffle feel.
public struct RhythmSettingsView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    // Preset time signatures for quick selection
    private let commonTimeSignatures: [TimeSignature] = [
        TimeSignature(beatsPerMeasure: 2, beatValue: 4),
        TimeSignature(beatsPerMeasure: 3, beatValue: 4),
        TimeSignature(beatsPerMeasure: 4, beatValue: 4),
        TimeSignature(beatsPerMeasure: 5, beatValue: 4),
        TimeSignature(beatsPerMeasure: 6, beatValue: 8),
        TimeSignature(beatsPerMeasure: 7, beatValue: 8),
        TimeSignature(beatsPerMeasure: 3, beatValue: 3)
    ]
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Time Signature Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Time Signature", systemImage: "metronome")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Custom Steppers for Beats and Beat Value
                    HStack(spacing: 4) {
                        Text("Custom:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // Beats Stepper (Numerator)
                        HStack(spacing: 2) {
                            Button(action: {
                                let newBeats = max(1, viewModel.timeSignature.beatsPerMeasure - 1)
                                viewModel.setTimeSignature(beats: newBeats, value: viewModel.timeSignature.beatValue)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 9, weight: .bold))
                                    .frame(width: 18, height: 20)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(viewModel.timeSignature.beatsPerMeasure)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .frame(minWidth: 22)
                            
                            Button(action: {
                                let newBeats = min(32, viewModel.timeSignature.beatsPerMeasure + 1)
                                viewModel.setTimeSignature(beats: newBeats, value: viewModel.timeSignature.beatValue)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 9, weight: .bold))
                                    .frame(width: 18, height: 20)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text("/")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Beat Value Stepper (Denominator, e.g. 3, 4, 8, etc.)
                        HStack(spacing: 2) {
                            Button(action: {
                                let newVal = max(1, viewModel.timeSignature.beatValue - 1)
                                viewModel.setTimeSignature(beats: viewModel.timeSignature.beatsPerMeasure, value: newVal)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 9, weight: .bold))
                                    .frame(width: 18, height: 20)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(viewModel.timeSignature.beatValue)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .frame(minWidth: 22)
                            
                            Button(action: {
                                let newVal = min(32, viewModel.timeSignature.beatValue + 1)
                                viewModel.setTimeSignature(beats: viewModel.timeSignature.beatsPerMeasure, value: newVal)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 9, weight: .bold))
                                    .frame(width: 18, height: 20)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    )
                }
                
                // Common preset chips
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
                                    .padding(.vertical, 5)
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
            
            // Subdivision & Timbre Row
            HStack(alignment: .top, spacing: 16) {
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
                
                Spacer()
                
                // Sound Timbre & Mute
                VStack(alignment: .leading, spacing: 8) {
                    Label("Timbre & Volume", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Picker("", selection: $viewModel.timbre) {
                            ForEach(Timbre.allCases, id: \.self) { timbre in
                                Text(timbre.displayName).tag(timbre)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        
                        Button(action: {
                            viewModel.toggleMute()
                        }) {
                            Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .foregroundColor(viewModel.isMuted ? .red : .secondary)
                                .frame(width: 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Groove & Shuffle Controls (with explanatory tooltip)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Groove & Shuffle Feel (搖擺律動)", systemImage: "waveform.path")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .help("Groove/Shuffle: 調整音符微觀長短比例。50%為直拍，66%為三連音搖擺(Triplet Swing)，75%為重搖擺(Hard Shuffle)")
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.grooveFeel.shuffleRatio * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                }
                
                HStack(spacing: 6) {
                    groovePresetButton(name: "Straight (直拍 50%)", ratio: 0.50)
                    groovePresetButton(name: "Light (58%)", ratio: 0.58)
                    groovePresetButton(name: "Triplet (搖擺 66%)", ratio: 2.0 / 3.0)
                    groovePresetButton(name: "Hard (重搖擺 75%)", ratio: 0.75)
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
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
            )
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
