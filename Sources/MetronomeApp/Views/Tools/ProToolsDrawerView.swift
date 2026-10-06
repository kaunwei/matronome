import SwiftUI
import MetronomeCore

/// Collapsible Pro Tools Drawer hosting Speed Trainer, Gap Trainer, Drone Tuner, and Practice Analytics.
public struct ProToolsDrawerView: View {
    @ObservedObject public var viewModel: MetronomeViewModel
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Toggle Bar
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.toggleToolsDrawer()
                }
            }) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundColor(.accentColor)
                    Text("Pro Tools & Practice Lab")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if viewModel.isSpeedTrainerActive || viewModel.isGapTrainerActive || viewModel.isDronePlaying {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(.caption2.bold())
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Image(systemName: viewModel.isToolsDrawerOpen ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Collapsible Content
            if viewModel.isToolsDrawerOpen {
                VStack(spacing: 12) {
                    Divider()
                    
                    // Segmented Tab Selector
                    HStack(spacing: 6) {
                        ForEach(ToolsTab.allCases) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedToolsTab = tab
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.iconName)
                                    Text(tab.rawValue)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(
                                    viewModel.selectedToolsTab == tab
                                        ? Color.accentColor
                                        : Color(nsColor: .controlBackgroundColor).opacity(0.6)
                                )
                                .foregroundColor(
                                    viewModel.selectedToolsTab == tab
                                        ? .white
                                        : .primary
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    // Tab Content Switcher
                    Group {
                        switch viewModel.selectedToolsTab {
                        case .speedTrainer:
                            SpeedTrainerView(viewModel: viewModel)
                        case .gapTrainer:
                            GapTrainerView(viewModel: viewModel)
                        case .droneTuner:
                            ReferenceDroneView(viewModel: viewModel)
                        case .practiceStats:
                            PracticeStatsDashboardView(viewModel: viewModel)
                        }
                    }
                    .transition(.opacity)
                }
                .padding(.bottom, 12)
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}
