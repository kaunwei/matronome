import SwiftUI
import MetronomeCore

/// Minimalist header displaying practice statistics (Session, Weekly, Total), reset triggers, and target countdown timer.
@MainActor
public struct PracticeTimeHeader: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    // Explicit State wrapper to avoid compiler macro requirements
    private var _customMinutes = SwiftUI.State(initialValue: "15")
    private var customMinutes: String {
        get { _customMinutes.wrappedValue }
        nonmutating set { _customMinutes.wrappedValue = newValue }
    }
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Main Top Bar
            HStack(spacing: 12) {
                // App Logo & Name
                HStack(spacing: 8) {
                    Image(systemName: "metronome.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.accentColor)
                    
                    Text("Metronome")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                
                // Playback status badge
                statusBadge
                
                Spacer()
                
                // Practice Stats Cluster
                HStack(spacing: 14) {
                    // Current Session Practice Time
                    HStack(spacing: 5) {
                        Image(systemName: "timer")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("SESSION")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Text(formatDuration(viewModel.currentPracticeTime))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            viewModel.resetCurrentPracticeSession()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(3)
                                .background(Circle().fill(Color.secondary.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                        .help("Reset current session timer")
                    }
                    
                    Divider().frame(height: 20)
                    
                    // Weekly Practice Time (with Weekly Reset)
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("THIS WEEK")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Text(formatTotalDuration(viewModel.weeklyPracticeTime))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            viewModel.resetWeeklyPracticeTime()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(3)
                                .background(Circle().fill(Color.secondary.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                        .help("Reset weekly practice total")
                    }
                    
                    Divider().frame(height: 20)
                    
                    // Lifetime Total Practice Time
                    HStack(spacing: 5) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ALL-TIME")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Text(formatTotalDuration(viewModel.totalPracticeTime))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Divider().frame(height: 20)
                    
                    // Target Countdown Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.toggleTargetTimerExpanded()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isTargetTimerRunning ? "hourglass.circle.fill" : "target")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(viewModel.isTargetTimerFinished ? .green : (viewModel.isTargetTimerRunning ? .accentColor : .secondary))
                            
                            if viewModel.targetCountdownDuration > 0 {
                                Text(formatDuration(viewModel.targetCountdownRemaining))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(viewModel.isTargetTimerFinished ? .green : (viewModel.isTargetTimerRunning ? .accentColor : .primary))
                            } else {
                                Text("Goal")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(viewModel.isTargetTimerExpanded ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Toggle practice target countdown timer")
                }
            }
            
            // Collapsible Target Countdown Timer Panel
            if viewModel.isTargetTimerExpanded {
                targetCountdownDrawer
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
    
    // MARK: - Status Badge
    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(viewModel.playbackState == .playing ? Color.green : (viewModel.playbackState == .paused ? Color.yellow : Color.secondary))
                .frame(width: 7, height: 7)
            
            Text(viewModel.playbackState.statusText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        )
    }
    
    // MARK: - Target Countdown Drawer
    private var targetCountdownDrawer: some View {
        VStack(spacing: 10) {
            Divider()
            
            HStack(spacing: 12) {
                // Countdown Presets
                HStack(spacing: 5) {
                    targetPresetButton(label: "5m", minutes: 5)
                    targetPresetButton(label: "10m", minutes: 10)
                    targetPresetButton(label: "15m", minutes: 15)
                    targetPresetButton(label: "30m", minutes: 30)
                    targetPresetButton(label: "45m", minutes: 45)
                    targetPresetButton(label: "60m", minutes: 60)
                }
                
                Spacer()
                
                // Target Countdown Progress & Display
                if viewModel.targetCountdownDuration > 0 {
                    HStack(spacing: 10) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(viewModel.isTargetTimerFinished ? "TARGET REACHED! 🎉" : "REMAINING")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(viewModel.isTargetTimerFinished ? .green : .secondary)
                            
                            Text(formatDuration(viewModel.targetCountdownRemaining))
                                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                .foregroundColor(viewModel.isTargetTimerFinished ? .green : (viewModel.isTargetTimerRunning ? .accentColor : .primary))
                        }
                        
                        Button(action: {
                            viewModel.toggleTargetTimer()
                        }) {
                            Image(systemName: viewModel.isTargetTimerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle().fill(viewModel.isTargetTimerRunning ? Color.orange : Color.accentColor)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            viewModel.resetTargetTimer()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.secondary.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Progress Bar
            if viewModel.targetCountdownDuration > 0 {
                let progress = max(0.0, min(1.0, 1.0 - (viewModel.targetCountdownRemaining / viewModel.targetCountdownDuration)))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 5)
                        
                        Capsule()
                            .fill(viewModel.isTargetTimerFinished ? Color.green : Color.accentColor)
                            .frame(width: geo.size.width * CGFloat(progress), height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(.top, 2)
    }
    
    private func targetPresetButton(label: String, minutes: Double) -> some View {
        let isSelected = (viewModel.targetCountdownDuration == minutes * 60)
        return Button(action: {
            viewModel.setTargetCountdownDuration(minutes * 60)
            viewModel.startTargetTimer()
        }) {
            Text(label)
                .font(.system(size: 10, weight: isSelected ? .bold : .semibold, design: .rounded))
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
    
    // MARK: - Time Format Helpers
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
    
    private func formatTotalDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        
        if hrs > 0 {
            return "\(hrs)h \(String(format: "%02d", mins))m"
        } else {
            let secs = total % 60
            return String(format: "%02d:%02d", mins, secs)
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
