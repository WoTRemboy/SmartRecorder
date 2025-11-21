//
//  AudioRecorderService.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 11.11.2025.
//

import Foundation
import AVFoundation
import Combine

final class AudioRecorderService: ObservableObject {
    
    @Published var amplitudes: [Float] = Array(repeating: 0, count: 16)
    private let engine = AVAudioEngine()
    private var isRecording = false
    private let audioQueue = DispatchQueue(label: "AudioRecorderService.queue")
    
    private var audioFile: AVAudioFile?
    private var fileURL: URL?
    
    func startRecording() async throws {
        guard !isRecording else { return }

        let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { allowed in
                cont.resume(returning: allowed)
            }
        }
        guard granted else {
            await MainActor.run { self.isRecording = false }
            throw NSError(domain: "AudioRecorderService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone permission not granted"])
        }

        // Do session configuration and engine start off the main thread
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            audioQueue.async { [weak self] in
                guard let self = self else { return cont.resume(returning: ()) }
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
                    try session.setActive(true, options: [])
                    
                    let input = self.engine.inputNode
                    let inputFormat = input.inputFormat(forBus: 0)
                    
                    let dir = FileManager.default.temporaryDirectory
                    let fileName = UUID().uuidString + ".m4a"
                    let url = dir.appendingPathComponent(fileName)
                    self.fileURL = url
                    self.audioFile = try AVAudioFile(forWriting: url, settings: inputFormat.settings, commonFormat: .pcmFormatFloat32, interleaved: false)

                    input.removeTap(onBus: 0)
                    input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, _) in
                        self?.processAudioBuffer(buffer)
                        if let strongSelf = self {
                            try? strongSelf.audioFile?.write(from: buffer)
                        }
                    }

                    try self.engine.start()

                    Task { @MainActor in
                        self.isRecording = true
                    }

                    cont.resume(returning: ())
                } catch {
                    Task { @MainActor in
                        self.isRecording = false
                    }
                    cont.resume(throwing: error)
                }
            }
        }
    }
    
    func stopRecording() async {
        guard isRecording else { return }
        await MainActor.run { self.isRecording = false }
        await withCheckedContinuation { cont in
            audioQueue.async { [weak self] in
                guard let self = self else { cont.resume(returning: ()); return }
                self.engine.inputNode.removeTap(onBus: 0)
                self.engine.stop()
                try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
                self.audioFile = nil
                cont.resume(returning: ())
            }
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0, let channelDataPointer = buffer.floatChannelData else { return }

        // Use first channel
        let channelData = channelDataPointer[0]
        let bandCount = amplitudes.count
        var bandValues = [Float](repeating: 0, count: bandCount)
        let samplesPerBand = max(frameLength / bandCount, 1)

        for band in 0..<bandCount {
            let start = band * samplesPerBand
            let end = min(start + samplesPerBand, frameLength)
            var sum: Float = 0
            var idx = start
            while idx < end {
                let sample = channelData[idx]
                sum += sample * sample
                idx += 1
            }
            let count = max(end - start, 1)
            let rms = sqrtf(sum / Float(count))
            bandValues[band] = rms
        }

        DispatchQueue.main.async { [bandValues] in
            self.amplitudes = bandValues
        }
    }
    
    func recordedFileURL() -> URL? {
        return fileURL
    }
}
