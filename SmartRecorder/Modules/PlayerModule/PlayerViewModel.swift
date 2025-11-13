//
//  PlayerViewModel.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 13.11.2025.
//

import Foundation
import AVKit
import os
internal import Combine

final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var isPlaying = false
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}

@Observable
final class PlayerViewModel {
    var isPlaying: Bool {
        get {
            delegate.isPlaying
        }
    }
    
    var currentTime: TimeInterval {
        get {
            player?.currentTime ?? 0.0
        }
        set {
            player?.currentTime = newValue
        }
    }
    
    var duration = 1.0
    
    private var player: AVAudioPlayer?
    private var delegate = PlayerDelegate()
    private var logger = Logger(subsystem: "todo.TODO.smart-recorder", category: "PlayerViewModel")
    
    // тестовое аудио не залито в репозиторий
    private let fileName = "testAudio"

    init() {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "flac") else {
            logger.critical("Test audio not found")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            currentTime = player.currentTime
            self.player = player
            player.delegate = delegate
            duration = player.duration
        } catch {
            logger.critical("Error initializing player: \(error)")
        }
    }
    
    func toggle() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        delegate.isPlaying.toggle()
    }
}
