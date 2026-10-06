import Foundation
import AVFAudio

/// Reference drone synthesizer generating continuous pure sine wave tuning tones (e.g. 440Hz - 442Hz).
public final class ReferenceDrone: @unchecked Sendable {
    public var baseFrequency: Double {
        didSet {
            rebuildBufferIfNeeded()
        }
    }

    public var isPlaying: Bool {
        return playerNode.isPlaying
    }

    public var volume: Float {
        get { playerNode.volume }
        set { playerNode.volume = max(0.0, min(1.0, newValue)) }
    }

    private let engine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    private let audioFormat: AVAudioFormat
    private var loopingBuffer: AVAudioPCMBuffer?

    public init(engine: AVAudioEngine, baseFrequency: Double = 440.0) {
        self.engine = engine
        self.playerNode = AVAudioPlayerNode()
        self.baseFrequency = baseFrequency
        self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) ?? AVAudioFormat()

        setupEngine()
        rebuildBufferIfNeeded()
    }

    private func setupEngine() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)
    }

    public func start() throws {
        if !engine.isRunning {
            try engine.start()
        }
        guard let buffer = loopingBuffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()
    }

    public func stop() {
        playerNode.stop()
    }

    public func setFrequency(_ frequency: Double) {
        self.baseFrequency = frequency
        if isPlaying {
            rebuildBufferIfNeeded()
            guard let buffer = loopingBuffer else { return }
            playerNode.stop()
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            playerNode.play()
        }
    }

    public func generateContinuousBuffer(frequency: Double, sampleRate: Double = 44100.0, duration: Double = 1.0) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return nil }
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let channels = Int(format.channelCount)
        let twoPi = 2.0 * Double.pi

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let sample = Float(sin(twoPi * frequency * time) * 0.4) // moderate amplitude to prevent clipping

            for ch in 0..<channels {
                buffer.floatChannelData?[ch][frame] = sample
            }
        }
        return buffer
    }

    private func rebuildBufferIfNeeded() {
        loopingBuffer = generateContinuousBuffer(frequency: baseFrequency, sampleRate: audioFormat.sampleRate, duration: 1.0)
    }
}
