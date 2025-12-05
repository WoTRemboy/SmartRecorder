//
//  PlayerViewModel.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 13.11.2025.
//

import Foundation
import AVKit
import OSLog
import Combine

private let logger = Logger(subsystem: "SmartRecorder", category: "PlayerViewModel")

@MainActor
final class PlayerViewModel: ObservableObject {
    
    private let delegate = PlayerDelegate()
    
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isPlaying: Bool = false

    // Slider state moved from ProgressBarView
    @Published var sliderProgress: CGFloat = 0.0
    @Published var totalWidth: CGFloat = 0.0
    @Published var sliderChangeInProgress: Bool = false
    @Published var currentTimeLabel: TimeInterval = 0.0

    // Aqualizer amplitudes used by PlayerScreenView
    @Published var amplitudes: [Float] = []

    private let note: Note
    private var player: AVAudioPlayer?
    private var amplitudeTimerCancellable: AnyCancellable?
    private let bandsCount: Int = 16
    
    internal var duration = 1.0
    
    init(note: Note) {
        self.note = note
        self.amplitudes = Array(repeating: 0, count: bandsCount)
        // Kick off async setup without blocking UI (no backend interaction)
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            if let path = note.audioPath, !path.isEmpty {
                let raw = path.trimmingCharacters(in: .whitespacesAndNewlines)
                let url: URL
                if raw.hasPrefix("file://") {
                    let tmp = URL(string: raw)
                    url = URL(fileURLWithPath: tmp?.path ?? raw)
                } else {
                    url = URL(fileURLWithPath: raw)
                }
                self.initializePlayer(with: url)
                self.isLoading = false
            } else {
                logger.critical("Audio path is missing for note: \(note.title, privacy: .private)")
                self.isLoading = false
            }
        }
    }
    
    private func initializePlayer(with url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            logger.error("Audio file does not exist at path: \(url.path(percentEncoded: false), privacy: .private)")
            return
        }
        
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? NSNumber {
            logger.debug("Audio file size: \(size.int64Value, privacy: .public) bytes")
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.isMeteringEnabled = true
            player.prepareToPlay()
            currentTime = player.currentTime
            self.player = player
            player.delegate = delegate
            delegate.onFinish = { [weak self] in
                guard let self else { return }
                self.isPlaying = false
                self.amplitudes = Array(repeating: 0, count: self.bandsCount)
                self.currentTimeLabel = 0
            }
            duration = player.duration
            startAmplitudeTimer()
        } catch {
            logger.error("Error initializing player with path: \(url.path, privacy: .private). Error: \(String(describing: error), privacy: .private)")
        }
    }
    
    private func startAmplitudeTimer() {
        amplitudeTimerCancellable?.cancel()
        amplitudeTimerCancellable = Timer.publish(every: 0.08, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.amplitudeTick()
            }
    }

    private func amplitudeTick() {
        // While user is scrubbing, freeze the current bars
        if sliderChangeInProgress {
            return
        }
        // If not playing, smoothly decay amplitudes
        guard isPlaying, let player = player else {
            if !amplitudes.isEmpty {
                let decayed = amplitudes.map { max(0, $0 * 0.85) }
                if decayed != amplitudes { amplitudes = decayed }
            }
            return
        }
        player.updateMeters()
        // Convert average power (in dB) to linear amplitude [0, ~1]
        let channel = 0
        let power = player.averagePower(forChannel: channel)
        let linear = pow(10.0, power / 20.0)
        let base = max(0.0, min(1.0, linear))

        var newValues = [Float](repeating: 0, count: bandsCount)
        for band in 0..<bandsCount {
            let normalizedIdx = Float(band) / Float(max(1, bandsCount - 1))
            let sinValue = sin(normalizedIdx * .pi)
            let jitter = Float.random(in: 0.5..<1.5)
            let value = Float(base) * (sinValue + 0.1) * jitter
            newValues[band] = value
        }
        amplitudes = newValues
        calcSliderProgress()
    }

    internal var noteName: String {
        note.title
    }
    
    internal var noteDate: Date {
        note.createdAt
    }
    
    var currentTime: TimeInterval {
        get {
            player?.currentTime ?? 0.0
        }
        set {
            let clamped = max(0, min(newValue, duration))
            player?.currentTime = clamped
            currentTimeLabel = clamped

            // Update slider progress if layout is known
            if totalWidth > 0 && duration > 0 {
                let fraction = CGFloat(clamped / duration).clamped(to: 0...1)
                sliderProgress = totalWidth * fraction
            }
        }
    }
    
    func togglePlayback() {
        if isLoading { return }
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
            player.updateMeters()
        }
    }

    // MARK: - Slider helpers
    
    func calcSliderProgress() {
        guard !sliderChangeInProgress else { return }
        guard totalWidth > 0, duration > 0 else {
            sliderProgress = 0
            currentTimeLabel = 0
            return
        }
        let clampedCurrent = max(0, min(currentTime, duration))
        let fraction = CGFloat(clampedCurrent / duration).clamped(to: 0...1)
        sliderProgress = totalWidth * fraction
        currentTimeLabel = clampedCurrent
    }

    func onSliderChanged(_ value: CGFloat) {
        guard totalWidth > 0, duration > 0 else { return }
        sliderProgress = min(totalWidth, max(value, 0.0))
        sliderChangeInProgress = true
        let fraction = (sliderProgress / totalWidth).clamped(to: 0...1)
        currentTimeLabel = TimeInterval(CGFloat(duration) * fraction)
    }

    func onSliderChangeEnded(_ value: CGFloat) {
        sliderChangeInProgress = false
        guard totalWidth > 0, duration > 0 else {
            return
        }
        let fraction = (sliderProgress / totalWidth).clamped(to: 0...1)
        let newTime = TimeInterval(CGFloat(duration) * fraction)
        currentTime = max(0, min(newTime, duration))
        currentTimeLabel = currentTime
        player?.updateMeters()
    }
    
    deinit {
        amplitudeTimerCancellable?.cancel()
    }
}

final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
