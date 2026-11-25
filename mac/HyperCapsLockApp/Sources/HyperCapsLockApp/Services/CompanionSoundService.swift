import AVFoundation
import Foundation

/// トリガーの押下と試聴に使う短い効果音をローカルで合成する。
final class CompanionSoundService: @unchecked Sendable {
    private struct VoicePhrase {
        let durationMs: Double
        let pitchCurve: @Sendable (Double) -> Double
    }

    private let queue = DispatchQueue(label: "com.hypercapslock.companion-sound", qos: .userInteractive)
    private let sampleRate: Double = 44_100
    private let format: AVAudioFormat

    private var engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [AVAudioPCMBuffer] = []
    private var nextPlayerIndex = 0
    private var lastPhraseIndex: Int?
    private var isEnabled = true
    private var isGraphConfigured = false
    private var idleStop: DispatchWorkItem?

    init() {
        self.format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        queue.async { [weak self] in
            self?.prepareBuffers()
        }
    }

    func setEnabled(_ enabled: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            self.isEnabled = enabled
            if !enabled {
                self.stopEngine()
            }
        }
    }

    func stopPlayback() {
        queue.async { [weak self] in
            self?.stopEngine()
        }
    }

    /// 相棒の可愛い声を 1 回再生する（オフ時や失敗時は何もしない）。
    func playTriggerVoice(ignoringEnabledFlag: Bool = false) {
        queue.async { [weak self] in
            guard let self else { return }
            guard ignoringEnabledFlag || self.isEnabled else { return }
            self.playNextPhrase()
        }
    }

    // MARK: - Private (audio queue only)

    private func prepareBuffers() {
        guard buffers.isEmpty else { return }

        let phrases: [VoicePhrase] = [
            // 1. 「ぴょっ♪」: 元気な基本の返事
            VoicePhrase(durationMs: 65) { progress in
                let eased = 1 - pow(1 - progress, 2)
                return 580 + (890 - 580) * eased
            },
            // 2. 「ぽわっ」: やわらかい返事
            VoicePhrase(durationMs: 72) { progress in
                let eased = sin(progress * .pi * 0.5)
                return 520 + (740 - 520) * eased
            },
            // 3. 「ぴぽっ」: 2音の小さな返事
            VoicePhrase(durationMs: 80) { progress in
                if progress < 0.42 {
                    let local = progress / 0.42
                    return 610 + 40 * local
                }
                let local = min(1.0, (progress - 0.42) / 0.14)
                return 650 + (920 - 650) * local
            },
            // 4. 「きゅん♪」: 山なりの愛らしい抑揚
            VoicePhrase(durationMs: 75) { progress in
                if progress < 0.6 {
                    let local = progress / 0.6
                    return 680 + (1020 - 680) * sin(local * .pi * 0.5)
                }
                let local = (progress - 0.6) / 0.4
                return 1020 - (1020 - 930) * local
            },
            // 5. 「んっ！」: 軽快で短い返事
            VoicePhrase(durationMs: 52) { progress in
                let eased = 1 - pow(1 - progress, 2)
                return 640 + (830 - 640) * eased
            },
        ]

        buffers = phrases.compactMap { synthesizeBuffer(for: $0) }
    }

    private func synthesizeBuffer(for phrase: VoicePhrase) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount((phrase.durationMs / 1000.0) * sampleRate)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else {
            return nil
        }

        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        let total = Double(frameCount)
        let attackFrames = min(total * 0.18, 0.006 * sampleRate)
        let releaseStart = total * 0.62
        let masterGain: Float = 0.22

        var phase = 0.0
        for i in 0..<Int(frameCount) {
            let idx = Double(i)
            let progress = idx / total
            let freq = phrase.pitchCurve(progress)
            phase += (2.0 * .pi * freq) / sampleRate

            // 基音＋やわらかな2・3倍音で小さな電子の相棒の声質を作る
            let fundamental = sin(phase)
            let secondHarmonic = 0.22 * sin(2.0 * phase)
            let thirdHarmonic = 0.06 * sin(3.0 * phase)
            let rawWave = (fundamental + secondHarmonic + thirdHarmonic) / 1.28

            // クリックノイズを防ぐ滑らかなコサイン窓エンベロープ
            let envelope: Double
            if idx < attackFrames, attackFrames > 0 {
                envelope = 0.5 * (1.0 - cos(.pi * (idx / attackFrames)))
            } else if idx >= releaseStart {
                let releaseProgress = (idx - releaseStart) / max(1.0, total - releaseStart)
                envelope = 0.5 * (1.0 + cos(.pi * releaseProgress))
            } else {
                envelope = 1.0
            }

            channelData[i] = Float(rawWave * envelope) * masterGain
        }

        return buffer
    }

    private func configureGraphIfNeeded() {
        guard !isGraphConfigured else { return }
        players = (0..<3).map { _ in AVAudioPlayerNode() }
        for player in players {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        isGraphConfigured = true
    }

    private func ensureEngineRunning() -> Bool {
        configureGraphIfNeeded()
        if engine.isRunning {
            return true
        }
        do {
            try engine.start()
            return true
        } catch {
            // オーディオ出力先切り替え等で失敗した場合はグラフを組み直す
            resetEngineGraph()
            configureGraphIfNeeded()
            do {
                try engine.start()
                return true
            } catch {
                return false
            }
        }
    }

    private func stopEngine() {
        idleStop?.cancel()
        idleStop = nil
        for player in players where player.isPlaying {
            player.stop()
        }
        if engine.isRunning {
            engine.stop()
        }
    }

    private func resetEngineGraph() {
        stopEngine()
        for player in players {
            engine.detach(player)
        }
        players.removeAll()
        engine = AVAudioEngine()
        isGraphConfigured = false
    }

    private func playNextPhrase() {
        prepareBuffers()
        guard !buffers.isEmpty, ensureEngineRunning(), !players.isEmpty else { return }

        let phraseIndex = pickPhraseIndex()
        lastPhraseIndex = phraseIndex
        let buffer = buffers[phraseIndex]

        let player = players[nextPlayerIndex]
        nextPlayerIndex = (nextPlayerIndex + 1) % players.count

        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }

        // 短い音が鳴り終わったら、使っていない音声エンジンを稼働させ続けない。
        idleStop?.cancel()
        let stop = DispatchWorkItem { [weak self] in self?.stopEngine() }
        idleStop = stop
        queue.asyncAfter(deadline: .now() + .seconds(1), execute: stop)
    }

    private func pickPhraseIndex() -> Int {
        guard buffers.count > 1 else { return 0 }
        var candidate = Int.random(in: 0..<buffers.count)
        if candidate == lastPhraseIndex {
            candidate = (candidate + 1 + Int.random(in: 0..<(buffers.count - 1))) % buffers.count
        }
        return candidate
    }
}
