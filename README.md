# Metronome for macOS

A high-precision, low-latency, modular metronome and rhythm training suite designed natively for macOS with Swift and SwiftUI.

---

## Key Features

### ⏱️ Precision Audio & Sound Synthesis
- **Zero-Latency PCM Audio Engine**: Built on `AVAudioEngine` for sample-accurate pulse generation without timing drift.
- **Multiple Sound Profiles**: Built-in sound packs including Digital synth, Woodblock, Mechanical click, Modern Beep, and Cowbell.
- **Downbeat Pitch Tuning**: Independent frequency control and pitch accents for Beat 1, standard beats, and subdivisions.

### 🎼 Advanced Time Signatures & Polyrhythmic Meter
- **Arbitrary Time Signatures**: Supports standard, odd, and non-standard meters including irregular rational fractions such as `3/3`, `5/4`, `7/8`, and `11/16`.
- **Dynamic Beat Slots**: Interactive per-beat indicators supporting accent, normal, ghost, and mute states.
- **Subdivisions & 6-Tuplets**: Seamlessly switch between Quarter, 8th, Triplet, 16th, Quintuplet, Sextuplet (6-tuplet), Septuplet, and 32nd subdivisions.
- **Shuffle & Swing Engine**: Smoothly adjustable swing ratio from straight time to hard triplet groove.

### 🏋️ Practice Suite & Rhythm Trainers
- **Speed Trainer**: Automatically ramps tempo up or down across bars to build technical facility.
- **Gap Trainer**: Cycles audible and silent bars to test and strengthen internal timekeeping.
- **Goal Countdown Timer**: Built-in target session timer with preset and custom durations (5m, 15m, 30m, 60m).

### 📊 Practice Tracking & Analytics
- **Practice Time Header**: Streamlined header tracking Session, Weekly, and Lifetime practice totals.
- **Weekly Reset**: Track weekly progress goals with manual or automatic resets.
- **14-Day Trends**: Visual 14-day history and consistency charts to maintain regular practice habits.

---

## Architecture & Project Structure

```
.
├── Sources/
│   ├── MetronomeCore/       # Audio engine, sound synthesis, time signature models, trainers
│   └── MetronomeApp/        # SwiftUI views, view models, visualizers, practice header
├── Tests/
│   ├── MetronomeCoreTests/  # Unit & timing verification tests
│   └── MetronomeAppTests/   # UI logic & view model tests
└── docs/
    └── SPEC.md              # Detailed technical specification
```

---

## Building and Running

### Requirements
- macOS 13.0+
- Swift 5.9+ / Xcode 15+

### Build & Test via Swift CLI
```bash
# Build the project
swift build

# Run unit and integration tests
swift test
```

---

## Specification

For the complete technical specification, refer to [docs/SPEC.md](file:///Volumes/Vault500G/workspace/matronome/docs/SPEC.md).
