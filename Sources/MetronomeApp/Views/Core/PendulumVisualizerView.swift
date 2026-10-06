import SwiftUI
import MetronomeCore

/// Smooth visual pendulum visualizer with physical rod, sliding bob, and angle oscillation.
public struct PendulumVisualizerView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let angle = calculateAngle(at: timeline.date)
            
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    // Pivot Cap / Mount
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.8), Color.black.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: 14)
                        .zIndex(2)
                    
                    // Swinging Pendulum Arm
                    VStack(spacing: 0) {
                        // Rod
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.secondary.opacity(0.5), Color.primary.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3, height: 100)
                        
                        // Weighted Bob
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentColor.opacity(0.8), Color.accentColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 24, height: 20)
                                .shadow(
                                    color: viewModel.playbackState == .playing ? Color.accentColor.opacity(0.5) : Color.clear,
                                    radius: 6
                                )
                            
                            // Bob Highlight Center
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 2, height: 10)
                        }
                    }
                    .rotationEffect(.degrees(angle), anchor: .top)
                    .animation(viewModel.playbackState == .stopped ? .spring(response: 0.5, dampingFraction: 0.7) : .none, value: angle)
                }
                .frame(height: 130)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
    
    private func calculateAngle(at date: Date) -> Double {
        guard viewModel.playbackState == .playing else {
            return 0.0
        }
        
        let secondsPerBeat = 60.0 / max(20.0, viewModel.bpm)
        let time = date.timeIntervalSinceReferenceDate
        // One complete back-and-forth swing takes 2 beats
        let phase = sin((time / secondsPerBeat) * Double.pi)
        let maxAngleDegrees: Double = 26.0
        return phase * maxAngleDegrees
    }
}
