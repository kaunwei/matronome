# Metronome Product Specification & Technical Reference

This document provides the complete, authoritative specification for the macOS native Metronome application built with Swift and SwiftUI.

---

## 1. Executive Overview

Metronome is a high-precision, low-latency, modular metronome and rhythm training suite tailored for musicians, educators, and audio professionals on macOS. It combines an ultra-stable CoreAudio/AVAudioEngine audio pipeline with rich visualization, advanced time signatures, polyrhythmic subdivisions, and comprehensive practice telemetry.

---

## 2. Core Audio Architecture & Sound Synthesis

### 2.1 Low-Latency Audio Engine
- **Engine**: Built upon `AVAudioEngine` and custom PCM buffer synthesis for zero-drift timekeeping.
- **Sample Rate & Precision**: 44.1 kHz / 48 kHz floating-point PCM buffers.
- **Audio Output Routing**: Dynamic device routing and hot-plug support via CoreAudio listeners.

### 2.2 Dynamic PCM Sound Synthesis & Sound Profiles
- **Sound Packs**:
  - `digital`: Crisp synthesized sine/square burst with short decay.
  - `wood`: Resonant woodblock transient synthesis with organic dampening.
  - `mechanical`: Classic mechanical metronome escapement impulse.
  - `beep`: Clean modern tone pip.
  - `cowbell`: Iconic percussion impulse with metallic undertones.
- **Downbeat Pitch Tuning**:
  - Independent frequency/pitch shaping for downbeat accents (Beat 1) vs. regular beats vs. subdivisions.
  - Configurable accent pitch boost (+2 to +12 semitones or custom frequencies) ensuring absolute metric clarity.

---

## 3. Rhythm Engine & Meter Capabilities

### 3.1 Custom Time Signatures & Non-Standard Meters
- Full support for arbitrary rational meters ($N / D$):
  - Standard: `4/4`, `3/4`, `2/4`, `6/8`, `12/8`, etc.
  - Odd & Complex: `5/4`, `7/8`, `9/8`, `11/16`.
  - Non-standard & Irregular denominators: e.g., `3/3` (triplet base measure), `5/6`, etc.
- **Dynamic Beat Slots**:
  - Dynamic slot visualization matching the exact numerator count.
  - Per-beat toggle for accent, normal, ghost, or mute states.

### 3.2 Advanced Subdivisions & Shuffle / Swing
- **Subdivision Modes**:
  - Quarter notes (1:1)
  - Eighth notes (1:2)
  - Triplets (1:3)
  - Sixteenth notes (1:4)
  - Quintuplets (1:5)
  - Sextuplets / 6-tuplets (1:6)
  - Septuplets (1:7) & 32nd notes (1:8)
- **Shuffle & Swing Engine**:
  - Continuously adjustable swing ratio (50% straight to 75% hard swing).
  - Micro-timing offset preservation across high BPM ranges (20 to 400 BPM).

---

## 4. Practice Suite & Training Modules

### 4.1 Speed Trainer (Tempo Automator)
- **Incremental Mode**: Automatically accelerates or decelerates BPM by $\Delta B$ every $N$ bars or seconds.
- **Target Boundaries**: Configurable start tempo, target tempo, step size, and loop/stop triggers.
- **Warm-up / Cooldown**: Optional laddering curves for structured technical routines.

### 4.2 Gap Trainer (Internal Clock Developer)
- **Mute Patterns**: Plays $M$ bars audible followed by $K$ bars silent.
- **Randomized Gap Mode**: Randomly drops bars or beats to stress-test internal rhythm stability.
- **Visual-Only Mode**: Retains visual pulse during audio dropouts or tests pure sensory independence.

---

## 5. Telemetry, Practice Tracking & Analytics

### 5.1 Practice Time Header & Session Management
- **Uncluttered Top Bar**: Clean visual aesthetic displaying session, weekly, and total practice statistics.
- **Current Session Timer**: Live-tracking active playing duration (pauses automatically when stopped).
- **Target Practice Timer**: Configurable countdown (e.g. 5m, 15m, 30m, 60m) with audible/visual target celebration.

### 5.2 Weekly Reset & 14-Day Practice Trends
- **Weekly Reset**: Manual or automated ISO-week boundary roll-over for weekly practice quotas.
- **14-Day Practice History**:
  - Daily aggregated training duration stored locally in persistent storage.
  - Visual trend breakdown illustrating daily consistency and volume over a rolling 14-day window.

---

## 6. User Interface & macOS Desktop Experience

### 6.1 Layout & Visual Feedback
- **Pendulum & Circular Beat Ring**: Smooth 60/120fps interpolated visualizers reflecting exact phase position.
- **Tactile Tempo Controls**: Stepper buttons (±1, ±5), direct BPM text entry, and Tap Tempo detection algorithm.
- **Dark/Light Mode**: Full native macOS vibrancy and theme adaptation.
- **Global Hotkeys & Spacebar Trigger**: Instant play/pause, tap tempo, and preset switching.
