import SwiftUI
import MetronomeCore

/// Dashboard view displaying lifetime practice statistics, 4-week long-term activity chart, daily history, and streak.
public struct PracticeStatsDashboardView: View {
    @ObservedObject public var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    private var stats: PracticeStats {
        viewModel.engine.practiceTracker.stats
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Practice Analytics & Long-Term Trends")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Track your consistency and practice duration over time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    viewModel.resetWeeklyPracticeTime()
                }) {
                    Text("Reset This Week")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            // Key Metric Cards Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                metricCard(
                    title: "This Week Practice",
                    value: formatDuration(viewModel.weeklyPracticeTime),
                    icon: "calendar",
                    tint: .orange
                )
                
                metricCard(
                    title: "All-Time Practice",
                    value: formatDuration(viewModel.totalPracticeTime),
                    icon: "clock.fill",
                    tint: .blue
                )
                
                metricCard(
                    title: "Active Streak",
                    value: "\(stats.currentStreak()) days",
                    icon: "flame.fill",
                    tint: .red
                )
                
                metricCard(
                    title: "Avg Session Tempo",
                    value: stats.totalSessionsCount > 0 ? String(format: "%.0f BPM", stats.weightedAverageTempo) : "–",
                    icon: "speedometer",
                    tint: .green
                )
            }
            
            // Long-Term Visual Chart: Last 14 Days Bar Chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Practice Trend (Last 14 Days)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Target: 30m / day")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                let summaries = stats.dailySummaries(lastDays: 14)
                let maxMinutes = max(30.0, (summaries.map { $0.totalDuration }.max() ?? 30.0) / 60.0)
                
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(summaries) { summary in
                        let minutes = summary.totalDuration / 60.0
                        let heightRatio = CGFloat(minutes / maxMinutes)
                        let isToday = Calendar.current.isDateInToday(summary.date)
                        
                        VStack(spacing: 3) {
                            if minutes > 0 {
                                Text(String(format: "%.0fm", minutes))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(minutes >= 30 ? Color.green : (minutes > 0 ? Color.accentColor : Color.secondary.opacity(0.15)))
                                .frame(height: max(4, heightRatio * 55))
                            
                            Text(dateString(from: summary.date))
                                .font(.system(size: 8, weight: isToday ? .bold : .regular))
                                .foregroundColor(isToday ? .accentColor : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                .cornerRadius(8)
            }
        }
        .padding(12)
    }
    
    private func metricCard(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm %02ds", minutes, seconds)
        }
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
