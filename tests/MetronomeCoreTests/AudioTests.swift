import Testing
import AVFAudio
@testable import MetronomeCore

struct AudioTests {

    @Test func testTimbreCasesAndDisplayNames() {
        let allTimbres = Timbre.allCases
        #expect(allTimbres.count == 5)
        #expect(Timbre.woodblock.displayName == "Woodblock")
        #expect(Timbre.digitalBeep.displayName == "Digital Beep")
        #expect(Timbre.studioClick.displayName == "Studio Click")
        #expect(Timbre.rimshot.displayName == "Rimshot")
        #expect(Timbre.sineSynth.displayName == "Sine Synth")
    }

    @Test func testDownbeatPitchMultiplier() {
        let unison = DownbeatPitch.unison
        #expect(abs(unison.frequencyMultiplier - 1.0) < 1e-4)

        let octave = DownbeatPitch.octaveUp
        #expect(abs(octave.frequencyMultiplier - 2.0) < 1e-4)

        let fifth = DownbeatPitch.perfectFifth
        #expect(abs(fifth.frequencyMultiplier - pow(2.0, 7.0 / 12.0)) < 1e-4)
    }

    @Test func testPCMClickSynthesizerAllTimbres() {
        let synth = PCMClickSynthesizer()

        for timbre in Timbre.allCases {
            for emphasis in [BeatEmphasis.downbeat, BeatEmphasis.accent, BeatEmphasis.normal, BeatEmphasis.ghost] {
                let buffer = synth.synthesizeBuffer(emphasis: emphasis, timbre: timbre)
                #expect(buffer != nil)
                guard let buf = buffer else { continue }

                #expect(buf.frameLength > 0)
                guard let channelData = buf.floatChannelData else {
                    #expect(Bool(false), "Missing channel data")
                    continue
                }

                // Verify zero clipping: samples must stay within [-1.0, 1.0]
                var maxVal: Float = 0.0
                for ch in 0..<Int(buf.format.channelCount) {
                    for frame in 0..<Int(buf.frameLength) {
                        let val = abs(channelData[ch][frame])
                        if val > maxVal { maxVal = val }
                    }
                }
                #expect(maxVal <= 1.0)
                #expect(maxVal > 0.0)
            }

            // Mute emphasis must return nil buffer
            let silentBuffer = synth.synthesizeBuffer(emphasis: .mute, timbre: timbre)
            #expect(silentBuffer == nil)
        }
    }

    @Test func testReferenceDroneGeneration() {
        let engine = AVAudioEngine()
        let drone = ReferenceDrone(engine: engine, baseFrequency: 440.0)

        #expect(drone.baseFrequency == 440.0)
        drone.setFrequency(442.0)
        #expect(drone.baseFrequency == 442.0)

        let buffer = drone.generateContinuousBuffer(frequency: 442.0, sampleRate: 44100.0, duration: 0.5)
        #expect(buffer != nil)
        guard let buf = buffer, let channelData = buf.floatChannelData else {
            #expect(Bool(false), "Failed to generate drone buffer")
            return
        }

        #expect(buf.frameLength == 22050)
        var maxVal: Float = 0.0
        for ch in 0..<Int(buf.format.channelCount) {
            for frame in 0..<Int(buf.frameLength) {
                let val = abs(channelData[ch][frame])
                if val > maxVal { maxVal = val }
            }
        }
        #expect(maxVal <= 1.0)
        #expect(maxVal > 0.0)
    }

    @Test func testMetronomeAudioEngineBufferCachingAndScheduling() {
        let engine = MetronomeAudioEngine()
        let cached = engine.createCachedBuffers()

        #expect(cached.count == 4) // downbeat, accent, normal, ghost (mute is excluded)
        #expect(cached[.downbeat] != nil)
        #expect(cached[.accent] != nil)
        #expect(cached[.normal] != nil)
        #expect(cached[.ghost] != nil)
        #expect(cached[.mute] == nil)

        // Verify scheduling does not crash
        engine.scheduleClick(emphasis: .downbeat)
        if let buf = cached[.accent] {
            engine.scheduleBuffer(buf)
        }
    }
}
