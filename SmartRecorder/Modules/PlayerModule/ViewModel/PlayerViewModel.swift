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
    // Delegate wiring will be set after player creation
    
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isPlaying: Bool = false
    
    private let note: Note
    private var player: AVAudioPlayer?
    
    internal var duration = 1.0
    
    init(note: Note) {
        self.note = note
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
            player.prepareToPlay()
            currentTime = player.currentTime
            self.player = player
            player.delegate = delegate
            delegate.onFinish = { [weak self] in
                guard let self else { return }
                self.isPlaying = false
            }
            duration = player.duration
        } catch {
            logger.error("Error initializing player with path: \(url.path, privacy: .private). Error: \(String(describing: error), privacy: .private)")
        }
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
            player?.currentTime = newValue
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
        }
    }
}

final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}
