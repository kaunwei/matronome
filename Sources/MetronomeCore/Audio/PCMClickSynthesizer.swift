import Foundation
import AVFAudio

/// Synthesizes pure PCM audio buffers in real-time for metronome clicks.
public struct PCMClickSynthesizer: Sendable {
    public var timbre: Timbre
    public var downbeatPitch: DownbeatPitch
    public var sampleRate: Double

    public init(
        timbre: Timbre = .woodblock,
        downbeatPitch: DownbeatPitch = .perfectFifth,
        sampleRate: Double = 44100.0
    ) {
        self.timbre = timbre
        self.downbeatPitch = downbeatPitch
        self.sampleRate = sampleRate
    }

    /// Synthesizes a PCM buffer for a given beat emphasis and timbre configuration.
    public func synthesizeBuffer(
        emphasis: BeatEmphasis,
        timbre: Timbre? = nil,
        format: AVAudioFormat? = nil
    ) -> AVAudioPCMBuffer? {
        guard emphasis.isAudible else {
            return nil
        }

        let activeTimbre = timbre ?? self.timbre
        let targetFormat = format ?? AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
        guard let audioFormat = targetFormat else { return nil }

        let sampleRate = audioFormat.sampleRate
        let channels = Int(audioFormat.channelCount)

        // Duration of click in seconds
        let duration: Double = clickDuration(for: activeTimbre)
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        let pitchMultiplier = (emphasis == .downbeat) ? downbeatPitch.frequencyMultiplier : 1.0
        let baseFreq = baseFrequency(for: activeTimbre) * pitchMultiplier
        let gain = Double(emphasis.gainMultiplier) * 0.8

        synthesizeSamples(
            timbre: activeTimbre,
            baseFrequency: baseFreq,
            gain: gain,
            sampleRate: sampleRate,
            frameCount: Int(frameCount),
            channels: channels,
            buffer: buffer
        )

        return buffer
    }

    private func clickDuration(for timbre: Timbre) -> Double {
        switch timbre {
        case .woodblock: return 0.045
        case .digitalBeep: return 0.035
        case .studioClick: return 0.025
        case .rimshot: return 0.055
        case .sineSynth: return 0.040
        }
    }

    private func baseFrequency(for timbre: Timbre) -> Double {
        switch timbre {
        case .woodblock: return 880.0
        case .digitalBeep: return 1760.0
        case .studioClick: return 1200.0
        case .rimshot: return 600.0
        case .sineSynth: return 1000.0
        }
    }

    private func synthesizeSamples(
        timbre: Timbre,
        baseFrequency: Double,
        gain: Double,
        sampleRate: Double,
        frameCount: Int,
        channels: Int,
        buffer: AVAudioPCMBuffer
    ) {
        guard let channelData = buffer.floatChannelData else { return }

        let twoPi = 2.0 * Double.pi
        var noiseSeed: UInt32 = 1234567

        for frame in 0..<frameCount {
            let t = Double(frame) / sampleRate
            let progress = Double(frame) / Double(frameCount)

            // Fast attack, exponential decay envelope
            let envelope: Double
            let attackFrames = max(1, Int(sampleRate * 0.002)) // 2ms attack to avoid pop
            if frame < attackFrames {
                envelope = Double(frame) / Double(attackFrames)
            } else {
                let decayProgress = Double(frame - attackFrames) / Double(frameCount - attackFrames)
                envelope = exp(-decayProgress * 7.0)
            }

            var sample: Double = 0.0

            switch timbre {
            case .woodblock:
                // Woodblock: Sine with fast pitch drop + subtle harmonics + resonance
                let pitchMod = exp(-progress * 25.0) * 0.5 + 1.0
                let freq = baseFrequency * pitchMod
                let osc1 = sin(twoPi * freq * t)
                let osc2 = 0.3 * sin(twoPi * (freq * 1.6) * t)
                sample = (osc1 + osc2) * envelope

            case .digitalBeep:
                // Digital Beep: Clean square / sine hybrid
                let sine = sin(twoPi * baseFrequency * t)
                let square = sine >= 0 ? 0.7 : -0.7
                sample = (0.7 * sine + 0.3 * square) * envelope

            case .studioClick:
                // Studio Click: High frequency pulse with fast resonant band
                let osc = sin(twoPi * baseFrequency * t)
                let clickPulse = exp(-progress * 40.0)
                sample = osc * clickPulse

            case .rimshot:
                // Rimshot: Metallic body + noise burst
                noiseSeed = (1103515245 &* noiseSeed &+ 12345) & 0x7fffffff
                let noise = (Double(noiseSeed) / Double(0x7fffffff) * 2.0 - 1.0) * 0.4
                let ring1 = sin(twoPi * baseFrequency * t)
                let ring2 = 0.5 * sin(twoPi * (baseFrequency * 2.2) * t)
                let body = (ring1 + ring2) * envelope
                let noiseBurst = noise * exp(-progress * 30.0)
                sample = body * 0.7 + noiseBurst * 0.3

            case .sineSynth:
                // Pure Sine Synth
                sample = sin(twoPi * baseFrequency * t) * envelope
            }

            // Zero clipping limiter / normalization
            let scaledSample = sample * gain * 0.8
            let clampedSample = max(-0.99, min(0.99, scaledSample))
            let floatSample = Float(clampedSample)

            for ch in 0..<channels {
                channelData[ch][frame] = floatSample
            }
        }
    }
}
