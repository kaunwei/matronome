import SwiftUI
import MetronomeCore

/// Sleek, balanced Tempo Control centerpiece integrating large BPM display, direct Tap Tempo, and primary Play/Pause.
@MainActor
public struct BPMDialView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    private var _isEditingDirect = SwiftUI.State(initialValue: false)
    private var _directBpmString = SwiftUI.State(initialValue: "")
    
    private var isEditingDirect: Bool {
        get { _isEditingDirect.wrappedValue }
        nonmutating set { _isEditingDirect.wrappedValue = newValue }
    }
    
    private var directBpmString: String {
        get { _directBpmString.wrappedValue }
        nonmutating set { _directBpmString.wrappedValue = newValue }
    }
    
    private var directBpmBinding: Binding<String> {
        _directBpmString.projectedValue
    }
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // Top: Italian tempo marking badge & Tap Tempo
            HStack {
                Text(viewModel.tempoMarking)
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .italic()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.12))
                    )
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                // Tap Tempo button
                Button(action: {
                    viewModel.tapTempo()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("TAP")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(viewModel.tapTempoTriggered ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.12))
                    )
                    .foregroundColor(viewModel.tapTempoTriggered ? .accentColor : .primary)
                    .scaleEffect(viewModel.tapTempoTriggered ? 0.94 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: viewModel.tapTempoTriggered)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("t", modifiers: [])
                .help("Tap Tempo (Hotkey: T)")
            }
            
            // Middle: BPM Number & Integrated Play/Pause Button
            HStack(spacing: 16) {
                // BPM Display (Click to edit)
                VStack(alignment: .leading, spacing: 0) {
                    if isEditingDirect {
                        TextField("BPM", text: directBpmBinding, onCommit: {
                            if let val = Double(directBpmString) {
                                viewModel.setBpm(val)
                            }
                            isEditingDirect = false
                        })
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .frame(width: 100)
                        .textFieldStyle(.plain)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(Int(viewModel.bpm))")
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .contentTransition(.numericText())
                                .onTapGesture {
                                    directBpmString = "\(Int(viewModel.bpm))"
                                    isEditingDirect = true
                                }
                                .help("Click to type BPM directly")
                            
                            Text("BPM")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Primary Play / Pause Button (With Spacebar shortcut)
                Button(action: {
                    viewModel.togglePlayPause()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .offset(x: viewModel.playbackState == .playing ? 0 : 1)
                        
                        Text(viewModel.playbackState == .playing ? "PAUSE" : "START")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(viewModel.playbackState == .playing ? Color.orange : Color.accentColor)
                            .shadow(
                                color: (viewModel.playbackState == .playing ? Color.orange : Color.accentColor).opacity(0.35),
                                radius: 6,
                                x: 0,
                                y: 2
                            )
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
                .help("Play / Pause (Hotkey: Spacebar)")
            }
            
            // Slider
            Slider(
                value: Binding(
                    get: { viewModel.bpm },
                    set: { viewModel.setBpm($0) }
                ),
                in: Tempo.minBPM...Tempo.maxBPM,
                step: 1.0
            )
            .accentColor(.accentColor)
            
            // Bottom Stepper Buttons Row
            HStack(spacing: 6) {
                stepperButton(label: "-10", delta: -10)
                stepperButton(label: "-5", delta: -5)
                stepperButton(label: "-1", delta: -1, isPrimary: true)
                
                Spacer()
                
                stepperButton(label: "+1", delta: 1, isPrimary: true)
                stepperButton(label: "+5", delta: 5)
                stepperButton(label: "+10", delta: 10)
            }
        }
        .padding(12)
    }
    
    private func stepperButton(label: String, delta: Double, isPrimary: Bool = false) -> some View {
        Button(action: {
            viewModel.incrementBpm(delta)
        }) {
            Text(label)
                .font(.system(size: isPrimary ? 13 : 11, weight: isPrimary ? .bold : .semibold, design: .rounded))
                .frame(minWidth: isPrimary ? 44 : 36, minHeight: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isPrimary ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isPrimary ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}
