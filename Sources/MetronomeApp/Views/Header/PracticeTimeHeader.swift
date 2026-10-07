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
                // App Logo
                Image(systemName: "metronome.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                // Practice Stats Cluster - Monospaced Fixed-Width Pills
                HStack(spacing: 8) {
                    // Current Session Practice Time Pill
                    statPill(
                        title: "SESSION",
                        icon: "timer",
                        iconColor: .accentColor,
                        value: formatDuration(viewModel.currentPracticeTime),
                        resetAction: { viewModel.resetCurrentPracticeSession() },
                        resetHelp: "Reset current session timer"
                    )
                    
                    // Weekly Practice Time Pill
                    statPill(
                        title: "WEEKLY",
                        icon: "calendar",
                        iconColor: .orange,
                        value: formatTotalDuration(viewModel.weeklyPracticeTime),
                        resetAction: { viewModel.resetWeeklyPracticeTime() },
                        resetHelp: "Reset weekly practice total"
                    )
                    
                    // Lifetime Total Practice Time Pill
                    statPill(
                        title: "TOTAL",
                        icon: "chart.bar.fill",
                        iconColor: .purple,
                        value: formatTotalDuration(viewModel.totalPracticeTime),
                        resetAction: nil,
                        resetHelp: nil
                    )
                    
                    // Target Countdown Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.toggleTargetTimerExpanded()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: viewModel.isTargetTimerRunning ? "hourglass.circle.fill" : "target")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(viewModel.isTargetTimerFinished ? .green : (viewModel.isTargetTimerRunning ? .accentColor : .secondary))
                            
                            if viewModel.targetCountdownDuration > 0 {
                                Text(formatDuration(viewModel.targetCountdownRemaining))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(viewModel.isTargetTimerFinished ? .green : (viewModel.isTargetTimerRunning ? .accentColor : .primary))
                                    .frame(minWidth: 56, alignment: .trailing)
                            } else {
                                Text("Goal")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .frame(height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(viewModel.isTargetTimerExpanded ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(viewModel.isTargetTimerExpanded ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
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
    
    // MARK: - Stat Pill Component
    private func statPill(
        title: String,
        icon: String,
        iconColor: Color,
        value: String,
        resetAction: (() -> Void)?,
        resetHelp: String?
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .frame(minWidth: 54, alignment: .trailing)
            
            if let resetAction = resetAction {
                Button(action: resetAction) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(2.5)
                        .background(Circle().fill(Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help(resetHelp ?? "Reset")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
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
                                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                                .foregroundColor(viewModel.isTargetTimerFinished ? .green : (viewModel.isTargetTimerRunning ? .accentColor : .primary))
                                .frame(minWidth: 68, alignment: .trailing)
                        }
                        
                        Button(action: {
                            viewModel.toggleTargetTimer()
                        }) {
                            Image(systemName: viewModel.isTargetTimerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(
                                    Circle().fill(viewModel.isTargetTimerRunning ? Color.orange : Color.accentColor)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            viewModel.resetTargetTimer()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
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
        let secs = total % 60
        
        if hrs > 0 {
            return "\(hrs)h \(String(format: "%02d", mins))m"
        } else if mins > 0 {
            return "\(mins)m \(String(format: "%02d", secs))s"
        } else {
            return "\(secs)s"
        }
    }
}
