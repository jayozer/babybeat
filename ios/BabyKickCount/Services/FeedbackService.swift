import AVFoundation
import UIKit

/// Plays synthesized tap sounds and triggers haptic feedback.
/// Uses AVAudioEngine to generate tones matching the web app's Web Audio counterpart.
@MainActor
final class FeedbackService {
    static let shared = FeedbackService()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private let sampleRate: Double = 44_100
    private var isStarted = false

    private init() {}

    func prepare() {
        haptic.prepare()
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-fatal — sound just won't play.
        }

        if !isStarted {
            engine.attach(player)
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            engine.connect(player, to: engine.mainMixerNode, format: format)
            do {
                try engine.start()
                player.play()
                isStarted = true
            } catch {
                // Non-fatal.
            }
        }
    }

    func trigger(sound: SoundOption, vibrationEnabled: Bool) {
        if sound != .none {
            play(sound)
        }
        if vibrationEnabled {
            haptic.impactOccurred()
        }
    }

    func play(_ sound: SoundOption) {
        guard sound != .none else { return }
        prepare()

        let buffer: AVAudioPCMBuffer?
        switch sound {
        case .softClick:
            buffer = makeSweep(startHz: 800, endHz: 400, duration: 0.10, gain: 0.30)
        case .pop:
            buffer = makeSweep(startHz: 600, endHz: 200, duration: 0.06, gain: 0.40)
        case .heartbeat:
            buffer = makeHeartbeat()
        case .bubble:
            buffer = makeSweep(startHz: 300, endHz: 500, duration: 0.12, gain: 0.25)
        case .none:
            buffer = nil
        }

        guard let buffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    // MARK: - Tone generation

    private func makeSweep(startHz: Float, endHz: Float, duration: Double, gain: Float) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        var phase: Float = 0
        let totalFrames = Float(frameCount)

        for i in 0..<Int(frameCount) {
            let t = Float(i) / totalFrames
            // Exponential ramp to match web app's exponentialRampToValueAtTime
            let freq = startHz * powf(endHz / startHz, t)
            let envelope = gain * expDecay(progress: t)
            channel[i] = envelope * sinf(phase)
            phase += 2 * .pi * freq / Float(sampleRate)
            if phase > 2 * .pi { phase -= 2 * .pi }
        }
        return buffer
    }

    private func makeHeartbeat() -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let duration = 0.26
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) { channel[i] = 0 }

        // First thump: 80 -> 60 Hz, 0.12s, gain 0.5
        mix(buffer: channel, sampleRate: sampleRate, offset: 0,
            startHz: 80, endHz: 60, duration: 0.12, gain: 0.5)
        // Second thump: 70 -> 50 Hz, 0.13s, gain 0.35, starting at 0.12s
        mix(buffer: channel, sampleRate: sampleRate,
            offset: Int(sampleRate * 0.12),
            startHz: 70, endHz: 50, duration: 0.13, gain: 0.35)

        return buffer
    }

    private func mix(buffer: UnsafeMutablePointer<Float>, sampleRate: Double, offset: Int,
                     startHz: Float, endHz: Float, duration: Double, gain: Float) {
        let frameCount = Int(sampleRate * duration)
        var phase: Float = 0
        let total = Float(frameCount)
        for i in 0..<frameCount {
            let t = Float(i) / total
            let freq = startHz * powf(endHz / startHz, t)
            let envelope = gain * expDecay(progress: t)
            buffer[offset + i] += envelope * sinf(phase)
            phase += 2 * .pi * freq / Float(sampleRate)
            if phase > 2 * .pi { phase -= 2 * .pi }
        }
    }

    private func expDecay(progress: Float) -> Float {
        // Matches exponentialRampToValueAtTime from 1.0 to ~0.01
        return powf(0.01, progress)
    }
}
