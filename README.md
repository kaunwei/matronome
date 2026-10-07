# Metronome for macOS

A high-precision, low-latency, modular metronome and rhythm training suite designed natively for macOS with Swift and SwiftUI.

---

## 🌟 Key Features

### ⏱️ Precision Audio & Dynamic Sound Synthesis
- **Zero-Latency PCM Audio Engine**: Built on `AVAudioEngine` for sample-accurate pulse generation without timing drift.
- **Multiple Sound Profiles**: Built-in sound timbres including Digital Beep, Woodblock, Mechanical Click, Studio Click, and Sine Synth.
- **Downbeat Pitch Tuning**: Independent frequency control and pitch accents for Beat 1, standard beats, and subdivisions.

### 🎼 Advanced Time Signatures & Polyrhythmic Meter
- **Arbitrary Time Signatures**: Supports standard, odd, and non-standard meters including irregular rational fractions such as `3/3`, `5/4`, `7/8`, and `11/16`.
- **Dynamic Beat Slots**: Interactive per-beat indicators supporting downbeat, accent, normal, ghost, and mute states.
- **Subdivisions & 6-Tuplets**: Seamlessly switch between Quarter (1/4), 8th (1/8), Triplet (1/3), 16th (1/16), and Sextuplet (6-tuplet / 1/24) subdivisions with horizontal scroll support.
- **Shuffle & Swing Engine**: Smoothly adjustable swing ratio from straight time (50%) to hard blues shuffle (75%).

### 🏋️ Practice Suite & Rhythm Trainers
- **Speed Trainer**: Automatically ramps tempo up or down across bars to build technical facility and guitar speed.
- **Gap Trainer**: Cycles audible and silent bars to test and strengthen internal timekeeping.
- **Goal Countdown Timer**: Built-in target session timer with preset and custom durations (5m, 10m, 15m, 30m, 45m, 60m).

### 📊 Practice Tracking & Analytics
- **Practice Time Header**: Streamlined header tracking Session, Weekly, and Lifetime practice totals with weekly resets.
- **14-Day Visual Trends**: Daily history, streaks, and consistency charts to maintain regular practice habits.
- **Dynamic 2-Column Preset Slots**: Save, recall, rename, and overwrite custom practice presets with hotkeys `1`–`9`.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Spacebar` | Play / Pause Metronome |
| `T` | Tap Tempo |
| `1` – `9` | Instant Preset Slot Recall |

---

## 🏛️ Architecture & Project Structure

```
.
├── Sources/
│   ├── MetronomeCore/       # Audio engine, sound synthesis, time signature models, trainers, stats
│   └── MetronomeApp/        # SwiftUI views, view models, visualizers, practice header
├── Tests/
│   └── MetronomeCoreTests/  # Unit & timing verification test suites (34 tests)
├── assets/
│   └── AppIcon_Source.jpeg  # High-resolution source icon artwork
├── scripts/
│   ├── build_app.sh         # Release packaging script generating build/Metronome.app
│   ├── generate_icon.py     # macOS multi-resolution AppIcon.icns generator
│   └── watch_worker.sh      # Background sentinel monitoring helper
└── docs/
    └── SPEC.md              # Detailed technical specification
```

---

## 🚀 Building, Testing & Running

### Requirements
- macOS 14.0+
- Swift 5.9+ / Xcode 15+

### Run via Swift CLI (Development)
```bash
# Run the application directly
swift run MetronomeApp

# Run full unit test suite
swift test
```

### Build Standalone macOS Application Bundle (.app)
```bash
# Package into build/Metronome.app & build/Metronome.zip
bash scripts/build_app.sh

# Open the build directory in Finder
open build/
```

---

## 📘 Specification

For the complete technical specification, architecture, and API details, refer to [docs/SPEC.md](file:///Volumes/Vault500G/workspace/matronome/docs/SPEC.md).
