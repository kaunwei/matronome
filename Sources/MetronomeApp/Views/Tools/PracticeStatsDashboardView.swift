import SwiftUI
import MetronomeCore

/// Dashboard view displaying lifetime practice statistics, weekly breakdown, daily history, and streak.
public struct PracticeStatsDashboardView: View {
    @ObservedObject public var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    private var stats: PracticeStats {
        viewModel.engine.practiceTracker.stats
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Practice Analytics")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Detailed breakdown of your practice routines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    viewModel.resetCurrentPracticeSession()
                }) {
                    Text("Reset Current Session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            // Key Metric Cards Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                metricCard(
                    title: "Total Practice Time",
                    value: formatDuration(viewModel.totalPracticeTime),
                    icon: "clock.fill",
                    tint: .blue
                )
                
                metricCard(
                    title: "Active Streak",
                    value: "\(stats.currentStreak()) days",
                    icon: "flame.fill",
                    tint: .orange
                )
                
                metricCard(
                    title: "Total Sessions",
                    value: "\(stats.totalSessionsCount)",
                    icon: "list.bullet.rectangle.portrait.fill",
                    tint: .purple
                )
                
                metricCard(
                    title: "Avg Session Tempo",
                    value: stats.totalSessionsCount > 0 ? String(format: "%.0f BPM", stats.weightedAverageTempo) : "–",
                    icon: "speedometer",
                    tint: .green
                )
            }
            
            // Last 7 Days Activity Mini-Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Last 7 Days (Minutes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                let summaries = stats.dailySummaries(lastDays: 7)
                let maxMinutes = max(1.0, (summaries.map { $0.totalDuration }.max() ?? 60.0) / 60.0)
                
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(summaries) { summary in
                        let minutes = summary.totalDuration / 60.0
                        let heightRatio = CGFloat(minutes / maxMinutes)
                        
                        VStack(spacing: 4) {
                            Text(String(format: "%.0fm", minutes))
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(minutes > 0 ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(height: max(4, heightRatio * 60))
                            
                            Text(dayOfWeekString(from: summary.date))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
            }
        }
        .padding(12)
    }
    
    private func metricCard(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.callout, design: .monospaced))
                    .bold()
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
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
    
    private func dayOfWeekString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
