import SwiftUI
import MetronomeCore

/// Playback transport controls: Play/Stop/Pause, Tap Tempo, and Mute triggers.
public struct TransportControlView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(spacing: 24) {
            // Tap Tempo Button
            Button(action: {
                viewModel.tapTempo()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("TAP")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .frame(width: 72, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(viewModel.tapTempoTriggered ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(viewModel.tapTempoTriggered ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1.5)
                )
                .foregroundColor(viewModel.tapTempoTriggered ? .accentColor : .primary)
                .scaleEffect(viewModel.tapTempoTriggered ? 0.94 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: viewModel.tapTempoTriggered)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("t", modifiers: [])
            .help("Tap Tempo (Hotkey: T)")
            
            // Primary Play / Stop Button
            Button(action: {
                viewModel.togglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.playbackState == .playing ? Color.red : Color.accentColor)
                        .frame(width: 72, height: 72)
                        .shadow(
                            color: (viewModel.playbackState == .playing ? Color.red : Color.accentColor).opacity(0.45),
                            radius: 12
                        )
                    
                    Image(systemName: viewModel.playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: viewModel.playbackState == .playing ? 0 : 2)
                }
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.space, modifiers: [])
            .help("Play / Pause (Hotkey: Spacebar)")
            
            // Stop / Reset Button
            Button(action: {
                viewModel.stop()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("STOP")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .frame(width: 72, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1.5)
                )
                .foregroundColor(viewModel.playbackState != .stopped ? .primary : .secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.playbackState == .stopped)
            .help("Stop & Reset (Hotkey: Esc)")
        }
        .padding(.vertical, 8)
    }
}
