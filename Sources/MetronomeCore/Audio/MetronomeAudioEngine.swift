import Foundation
import AVFAudio

/// Audio playback engine managing low-latency buffer scheduling via AVAudioEngine and AVAudioPlayerNode.
public final class MetronomeAudioEngine: @unchecked Sendable {
    public let engine: AVAudioEngine
    public let playerNode: AVAudioPlayerNode
    public let droneNode: AVAudioPlayerNode
    public var synthesizer: PCMClickSynthesizer
    public private(set) var audioFormat: AVAudioFormat

    public var volume: Float {
        get { playerNode.volume }
        set { playerNode.volume = max(0.0, min(1.0, newValue)) }
    }

    public var isRunning: Bool {
        return engine.isRunning
    }

    public init(synthesizer: PCMClickSynthesizer = PCMClickSynthesizer()) {
        self.engine = AVAudioEngine()
        self.playerNode = AVAudioPlayerNode()
        self.droneNode = AVAudioPlayerNode()
        self.synthesizer = synthesizer
        self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) ?? AVAudioFormat()

        setupEngine()
    }

    private func setupEngine() {
        engine.attach(playerNode)
        engine.attach(droneNode)

        let mainMixer = engine.mainMixerNode
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)

        let standardFormat = AVAudioFormat(
            standardFormatWithSampleRate: outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44100.0,
            channels: outputFormat.channelCount > 0 ? outputFormat.channelCount : 2
        ) ?? AVAudioFormat()

        self.audioFormat = standardFormat

        engine.connect(playerNode, to: mainMixer, format: standardFormat)
        engine.connect(droneNode, to: mainMixer, format: standardFormat)
    }

    public func start() throws {
        if !engine.isRunning {
            try engine.start()
        }
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    public func stop() {
        playerNode.stop()
        droneNode.stop()
        if engine.isRunning {
            engine.stop()
        }
    }

    /// Pre-synthesizes and caches click buffers for all beat emphasis levels.
    public func createCachedBuffers(timbre: Timbre? = nil) -> [BeatEmphasis: AVAudioPCMBuffer] {
        var buffers: [BeatEmphasis: AVAudioPCMBuffer] = [:]
        for emphasis in BeatEmphasis.allCases {
            if let buffer = synthesizer.synthesizeBuffer(emphasis: emphasis, timbre: timbre, format: audioFormat) {
                buffers[emphasis] = buffer
            }
        }
        return buffers
    }

    /// Schedules an immediate click buffer for low latency playback.
    public func scheduleClick(emphasis: BeatEmphasis, timbre: Timbre? = nil) {
        guard let buffer = synthesizer.synthesizeBuffer(emphasis: emphasis, timbre: timbre, format: audioFormat) else {
            return
        }
        scheduleBuffer(buffer)
    }

    /// Schedules a pre-synthesized PCM buffer.
    public func scheduleBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime? = nil) {
        if !playerNode.isPlaying {
            playerNode.play()
        }
        playerNode.scheduleBuffer(buffer, at: time, options: [], completionHandler: nil)
    }
}
