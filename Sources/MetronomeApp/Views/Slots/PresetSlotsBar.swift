import SwiftUI
import MetronomeCore

/// Dynamic 2-column preset slots bar with elongated cards, hotkeys (1-9), snapshot recall, and scroll indicator.
@MainActor
public struct PresetSlotsBar: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    // Explicit State wrappers to avoid compiler macro requirement
    private var _isAddingPreset = SwiftUI.State(initialValue: false)
    private var _newPresetName = SwiftUI.State(initialValue: "")
    private var _renamingPresetId = SwiftUI.State<UUID?>(initialValue: nil)
    private var _renamePresetName = SwiftUI.State(initialValue: "")
    
    private var isAddingPreset: Bool {
        get { _isAddingPreset.wrappedValue }
        nonmutating set { _isAddingPreset.wrappedValue = newValue }
    }
    private var newPresetName: String {
        get { _newPresetName.wrappedValue }
        nonmutating set { _newPresetName.wrappedValue = newValue }
    }
    private var renamingPresetId: UUID? {
        get { _renamingPresetId.wrappedValue }
        nonmutating set { _renamingPresetId.wrappedValue = newValue }
    }
    private var renamePresetName: String {
        get { _renamePresetName.wrappedValue }
        nonmutating set { _renamePresetName.wrappedValue = newValue }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    public init(viewModel: MetronomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header label
            HStack {
                Label("PRESET SLOTS (\(viewModel.presets.count))", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Hotkeys 1-9")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
                
                Button(action: {
                    newPresetName = "Slot \(viewModel.presets.count + 1)"
                    isAddingPreset = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Save New Slot")
                    }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.12))
                    )
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("Save current settings as a new preset")
            }
            
            // 2-Column Elongated Cards Grid inside Vertical ScrollView with visible scroll indicators
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(viewModel.presets.enumerated()), id: \.element.id) { index, preset in
                        elongatedSlotCard(for: preset, index: index)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 140)
            
            // Inline Add Dialog
            if isAddingPreset {
                inlineAddBar
            }
            
            // Inline Rename Dialog
            if renamingPresetId != nil {
                inlineRenameBar
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
    
    // MARK: - Elongated 2-Column Slot Card
    @ViewBuilder
    private func elongatedSlotCard(for preset: MetronomePreset, index: Int) -> some View {
        let isSelected = (viewModel.selectedPresetId == preset.id)
        let hotkeyNumber = index < 9 ? "\(index + 1)" : nil
        
        Button(action: {
            viewModel.recallPreset(preset)
        }) {
            HStack(spacing: 8) {
                // Hotkey badge
                if let hotkey = hotkeyNumber {
                    Text(hotkey)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                        )
                }
                
                // Name & parameters
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(size: 12, weight: isSelected ? .bold : .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 4) {
                        Text("\(Int(preset.bpm)) BPM")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                        
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text(preset.timeSignature.description)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Recall Preset") {
                viewModel.recallPreset(preset)
            }
            
            Button("Overwrite with Current Settings") {
                viewModel.overwritePresetWithCurrentState(id: preset.id)
            }
            
            Button("Rename...") {
                renamePresetName = preset.name
                renamingPresetId = preset.id
            }
            
            Divider()
            
            Button("Delete Preset", role: .destructive) {
                viewModel.deletePreset(id: preset.id)
            }
        }
        .background {
            if index < 9 {
                hotkeyReceiver(index: index + 1)
            }
        }
    }
    
    // MARK: - Hotkey Button Helper
    @ViewBuilder
    private func hotkeyReceiver(index: Int) -> some View {
        let char = Character("\(index)")
        Button("") {
            viewModel.recallPreset(at: index)
        }
        .keyboardShortcut(KeyEquivalent(char), modifiers: [])
        .opacity(0)
        .frame(width: 0, height: 0)
    }
    
    // MARK: - Inline Add Dialog
    private var inlineAddBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.square.fill")
                .foregroundColor(.accentColor)
            
            TextField("Preset Name", text: _newPresetName.projectedValue)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
            
            Button("Save") {
                viewModel.saveCurrentAsPreset(name: newPresetName)
                isAddingPreset = false
            }
            .font(.system(size: 11, weight: .semibold))
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                isAddingPreset = false
            }
            .font(.system(size: 11))
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
    
    // MARK: - Inline Rename Dialog
    private var inlineRenameBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil")
                .foregroundColor(.accentColor)
            
            TextField("New Name", text: _renamePresetName.projectedValue)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
            
            Button("Rename") {
                if let id = renamingPresetId {
                    viewModel.renamePreset(id: id, newName: renamePresetName)
                }
                renamingPresetId = nil
            }
            .font(.system(size: 11, weight: .semibold))
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                renamingPresetId = nil
            }
            .font(.system(size: 11))
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
