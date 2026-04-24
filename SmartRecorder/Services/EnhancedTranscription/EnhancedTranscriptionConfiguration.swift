//
//  EnhancedTranscriptionConfiguration.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 04/24/2025.
//

import Foundation
@preconcurrency import AVFoundation
import whisper

struct EnhancedTranscriptionConfiguration {
    let modelResourceName = "ggml-large-v3-turbo-q5_0"
    let chunkDuration: Double = 20
    let overlapDuration: Double = 2
    let languageCode = "ru"

    var targetFormat: AVAudioFormat? {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(WHISPER_SAMPLE_RATE),
            channels: 1,
            interleaved: false
        )
    }
}
