import SwiftUI
import MetronomeCore

/// Minimalist, large BPM rotary dial and numerical stepper view.
@MainActor
public struct BPMDialView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    private var _isHovering = SwiftUI.State(initialValue: false)
    private var _isEditingDirect = SwiftUI.State(initialValue: false)
    private var _directBpmString = SwiftUI.State(initialValue: "")
    
    private var isHovering: Bool {
        get { _isHovering.wrappedValue }
        nonmutating set { _isHovering.wrappedValue = newValue }
    }
    
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
    
    private var normalizedBpm: Double {
        let minBpm = Tempo.minBPM
        let maxBpm = Tempo.maxBPM
        return (viewModel.bpm - minBpm) / (maxBpm - minBpm)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Main Dial & BPM Centerpiece
            ZStack {
                // Background Track Arc
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(
                        Color.secondary.opacity(0.2),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: 220, height: 220)
                
                // Active Progress Arc
                Circle()
                    .trim(from: 0.15, to: 0.15 + (normalizedBpm * 0.70))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.accentColor.opacity(0.7), Color.accentColor, Color.orange]),
                            center: .center,
                            startAngle: .degrees(144),
                            endAngle: .degrees(396)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: 220, height: 220)
                    .shadow(color: Color.accentColor.opacity(viewModel.playbackState == .playing ? 0.35 : 0.0), radius: 8)
                
                // Center Display
                VStack(spacing: 4) {
                    Text("TEMPO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    if isEditingDirect {
                        TextField("BPM", text: directBpmBinding, onCommit: {
                            if let val = Double(directBpmString) {
                                viewModel.setBpm(val)
                            }
                            isEditingDirect = false
                        })
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .frame(width: 140)
                        .textFieldStyle(.plain)
                    } else {
                        Text("\(Int(viewModel.bpm))")
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText())
                            .onTapGesture {
                                directBpmString = "\(Int(viewModel.bpm))"
                                isEditingDirect = true
                            }
                            .help("Click to type BPM directly")
                    }
                    
                    Text("BPM")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    // Italian Tempo Marking Badge
                    Text(viewModel.tempoMarking)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .italic()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.12))
                        )
                        .foregroundColor(.accentColor)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let vector = CGVector(dx: value.location.x - 110, dy: value.location.y - 110)
                        let angle = atan2(vector.dy, vector.dx) // -pi to +pi
                        var degrees = angle * 180 / .pi
                        if degrees < 0 { degrees += 360 }
                        // Map 144..396 (range 252 degrees)
                        var angleFromStart = degrees - 144
                        if angleFromStart < 0 { angleFromStart += 360 }
                        if angleFromStart <= 252 {
                            let fraction = angleFromStart / 252.0
                            let targetBpm = Tempo.minBPM + fraction * (Tempo.maxBPM - Tempo.minBPM)
                            viewModel.setBpm(targetBpm.rounded())
                        }
                    }
            )
            
            // Stepper Buttons Row
            HStack(spacing: 8) {
                stepperButton(label: "-10", delta: -10)
                stepperButton(label: "-5", delta: -5)
                stepperButton(label: "-1", delta: -1, isPrimary: true)
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 4)
                
                stepperButton(label: "+1", delta: 1, isPrimary: true)
                stepperButton(label: "+5", delta: 5)
                stepperButton(label: "+10", delta: 10)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func stepperButton(label: String, delta: Double, isPrimary: Bool = false) -> some View {
        Button(action: {
            viewModel.incrementBpm(delta)
        }) {
            Text(label)
                .font(.system(size: isPrimary ? 13 : 11, weight: isPrimary ? .bold : .semibold, design: .rounded))
                .frame(minWidth: isPrimary ? 40 : 34, minHeight: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isPrimary ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isPrimary ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}
