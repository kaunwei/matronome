# Metronome Domain Glossary

This document defines the canonical vocabulary for the macOS Metronome Desktop App.

## Language

**Tempo**:
The speed of the rhythm measured strictly in Beats Per Minute (BPM, typically 20 to 400).
_Avoid_: Speed, pace, rate

**TimeSignature**:
The meter definition consisting of beats per measure (numerator) and the reference beat unit (denominator, e.g., 4/4, 6/8, 7/8).
_Avoid_: Meter format, bar spec

**Subdivision**:
The rhythmic division of a single beat into smaller equal pulses (e.g., Quarter, Eighth, Triplet, Sixteenth, Sextuplet).
_Avoid_: Micro-beat, sub-pulse

**GrooveFeel / Shuffle**:
The timing displacement applied to subdivisions to produce swing or shuffle feel (from 50% straight to 75% hard swing).
_Avoid_: Swing ratio, groove offset

**BeatEmphasis**:
The accent level assigned to a specific pulse within a measure (Downbeat, Accent, Normal, Ghost, Rest/Mute).
_Avoid_: Beat weight, tick volume

**DownbeatPitch**:
The distinct audio frequency or pitch semitone offset configured specifically for the first beat (downbeat) of each measure.
_Avoid_: First tone, root pitch, bar tone

**Timbre**:
The synthesized or sampled audio sonic character used for clicks (e.g., Mechanical Woodblock, Digital Beep, Studio Click, Rimshot, Sine Synth).
_Avoid_: Sound effect, tone type, skin

**PresetSlot**:
A configurable snapshot holding a full set of practice parameters (Tempo, TimeSignature, Subdivision, Shuffle, Timbre, DownbeatPitch, Pattern) that can be dynamically created, edited, and recalled.
_Avoid_: Memory slot, bookmark, macro

**CurrentPracticeTime**:
The active duration accumulated in the current practice session (resets when requested or upon session end).
_Avoid_: Session timer, current duration

**TotalPracticeTime**:
The persistent cumulative practice duration across all sessions stored in persistent storage.
_Avoid_: Lifetime timer, global duration

**PracticeTracker**:
The domain service responsible for tracking elapsed active practice time and persisting total practice duration.
_Avoid_: Timer logger, stopwatch service

**PracticeTargetTimer**:
A countdown timer or measure goal that halts playback and notifies the musician when target practice time is reached.
_Avoid_: Alarm, auto stopper

**SpeedTrainer**:
An automated training mode that increments or decrements Tempo by specified BPM steps after a set number of measures.
_Avoid_: Tempo ramp, accelerator

**GapTrainer**:
A rhythmic training mode that mutes audio for configured intervals (e.g. 3 bars sound, 1 bar silence) to develop internal timing.
_Avoid_: Mute trainer, silent practice

**ReferenceDrone**:
A sustained sine/saw reference pitch generator (e.g., A4 = 440Hz ~ 442Hz) for tuning and intonation practice.
_Avoid_: Tuner tone, pitch drone

**PracticeStats**:
Aggregated daily and weekly practice metrics including time spent, tempos practiced, and slot usage history.
_Avoid_: Activity logs, practice records
