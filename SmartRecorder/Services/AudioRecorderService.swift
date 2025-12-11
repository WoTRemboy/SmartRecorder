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
    
    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var fileName: String?
    
    func recordedFileName() -> String? {
        return fileName
    }
    
    static func url(forFileName fileName: String?) -> URL? {
        guard let name = fileName, !name.isEmpty else { return nil }
        return FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }
    
    func startRecording() async throws {
        guard !isRecording else { return }

        let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { allowed in
                cont.resume(returning: allowed)
            }
        }
        guard granted else {
            await MainActor.run { self.isRecording = false }
            Toast.shared.present(title: Texts.RecorderPage.Toasts.accessDenied)
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
                    
                    let fileName = UUID().uuidString + ".m4a"
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    self.fileName = fileName

                    // AAC in M4A settings
                    let settings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]

                    self.recorder = try AVAudioRecorder(url: url, settings: settings)
                    self.recorder?.isMeteringEnabled = true
                    self.recorder?.prepareToRecord()
                    self.recorder?.record()

                    // Start metering timer to update amplitudes ~20 fps
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.meterTimer?.invalidate()
                        self.meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                            self?.updateAmplitudesFromRecorder()
                        }
                    }

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
                self.recorder?.stop()
                self.recorder = nil
                self.meterTimer?.invalidate()
                self.meterTimer = nil
                try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
                cont.resume(returning: ())
            }
        }
    }
    
    private func updateAmplitudesFromRecorder() {
        guard let recorder = recorder else { return }
        recorder.updateMeters()
        // Convert average power (dB) to linear 0...1
        let avgPower = recorder.averagePower(forChannel: 0) // -160...0 dB
        let level = max(0.0, min(1.0, pow(10.0, avgPower / 20.0)))

        var bandValues = [Float](repeating: 0, count: amplitudes.count)
        for band in 0..<amplitudes.count {
            let linearRandomValue = Float.random(in: 0.5..<1.5)
            let normalizedBandIdx = Float(band) / Float(amplitudes.count - 1)
            let sinValue = sin(normalizedBandIdx * .pi)
            let amplitude = Float(level) * (sinValue + 0.1) * linearRandomValue
            bandValues[band] = amplitude
        }
        DispatchQueue.main.async { [bandValues] in
            self.amplitudes = bandValues
        }
    }
}
