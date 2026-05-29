//
//  AudioRecorderService.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 11.11.2025.
//

import Foundation
import AVFoundation
import Combine
import OSLog
import whisper

final class AudioRecorderService: ObservableObject {

    @Published var amplitudes: [Float] = Array(repeating: 0, count: 16)
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SmartRecorder", category: "AudioRecorderService")
    private var preferredInput: AVAudioSessionPortDescription?
    private var session: AVAudioSession?
    @Published private(set) var transcriptionText: String = ""
    @Published private(set) var isTranscribing: Bool = false

    private var engine = AVAudioEngine()
    private var isRecording = false
    private let audioQueue = DispatchQueue(label: "AudioRecorderService.queue")

    private var recorder: AVAudioRecorder?
    private var fileName: String?

    enum RecordingError: LocalizedError {
        case microphonePermissionDenied
        case preparationFailed
        case startFailed

        var errorDescription: String? {
            switch self {
            case .microphonePermissionDenied:
                return "Microphone permission not granted"
            case .preparationFailed:
                return "Unable to prepare audio recorder"
            case .startFailed:
                return "Unable to start audio recording"
            }
        }
    }
    
    private var converter: AVAudioConverter?
    private var converterInputFormat: AVAudioFormat?
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: Double(WHISPER_SAMPLE_RATE),
        channels: 1,
        interleaved: false
    )

    private let transcriptionService = WhisperTranscriptionService()
    private var collectedSamples: [Float] = []
    private var lastTranscribedSampleIndex = 0
    private var transcriptionTask: Task<Void, Never>?

    private let transcriptionChunkDuration: Double = 2.0
    private let overlapDuration: Double = 0.5
    private let minimumFinalChunkDuration: Double = 0.8
    private let minimumSpeechRMS: Float = 0.006
    private let recordingMeterGain: Float = 2.0

    func recordedFileName() -> String? {
        fileName
    }

    func discardRecordingFile() {
        guard let fileURL = Self.url(forFileName: fileName) else { return }

        do {
            try FileManager.default.removeItem(at: fileURL)
            fileName = nil
        } catch {
            logger.error("Failed to delete discarded recording: \(String(describing: error))")
        }
    }

    static func url(forFileName fileName: String?) -> URL? {
        guard let name = fileName, !name.isEmpty else { return nil }
        return FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }
    
    func prepareAudioSession() throws {
        session = AVAudioSession.sharedInstance()
        guard let session else { return }

        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true, options: [])
        try applyPreferredInput(in: session)
    }
    
    // TODO: throw it in a separate Task
    func observeRouteChanges() async {
        // Observe route change notifications.
        for await notification in NotificationCenter.default.notifications(
            named: AVAudioSession.routeChangeNotification
        ) {
            print(notification)
        }
    }
    
    func getMicrophones() -> [AVAudioSessionPortDescription] {
        let audioSession = session ?? AVAudioSession.sharedInstance()
        return audioSession.availableInputs ?? []
    }

    func selectedMicrophone() -> AVAudioSessionPortDescription? {
        let audioSession = session ?? AVAudioSession.sharedInstance()
        let inputs = audioSession.availableInputs ?? []

        if let preferredInput,
           let input = inputs.first(where: { $0.uid == preferredInput.uid }) {
            return input
        }

        if let routeInput = audioSession.currentRoute.inputs.first,
           let input = inputs.first(where: { $0.uid == routeInput.uid }) {
            preferredInput = input
            return input
        }

        preferredInput = inputs.first
        return preferredInput
    }
    
    @discardableResult
    func chooseMicrophone(microphone: AVAudioSessionPortDescription) throws -> AVAudioSessionPortDescription {
        let inputs = session?.availableInputs ?? []
        let resolvedInput = inputs.first { $0.uid == microphone.uid } ?? microphone
        preferredInput = resolvedInput
        return resolvedInput
    }
    
    func startRecording() async throws {
        guard !isRecording else { return }

        let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { allowed in
                cont.resume(returning: allowed)
            }
        }
        guard granted else {
            isRecording = false
            Toast.shared.present(title: Texts.RecorderPage.Toasts.accessDenied)
            throw RecordingError.microphonePermissionDenied
        }

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            audioQueue.async { [weak self] in
                guard let self = self else { return cont.resume(returning: ()) }
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
                    try session.setActive(true, options: [])
                    try self.applyPreferredInput(in: session)

                    let fileName = UUID().uuidString + ".m4a"
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    self.fileName = fileName
                    self.resetStreamingState()
                    self.engine.stop()
                    self.engine.inputNode.removeTap(onBus: 0)
                    self.engine = AVAudioEngine()
                    self.converter = nil
                    self.converterInputFormat = nil
                    self.isRecording = true

                    let settings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]

                    let didConfigureEngineTap = self.configureEngineTap()
                    if didConfigureEngineTap {
                        self.engine.prepare()
                        try self.engine.start()
                    }

                    self.recorder = try AVAudioRecorder(url: url, settings: settings)
                    self.recorder?.isMeteringEnabled = true
                    guard self.recorder?.prepareToRecord() == true else {
                        self.resetRecorderAfterFailedStart(url: url)
                        throw RecordingError.preparationFailed
                    }
                    guard self.recorder?.record() == true else {
                        self.resetRecorderAfterFailedStart(url: url)
                        throw RecordingError.startFailed
                    }

                    cont.resume(returning: ())
                } catch {
                    self.isRecording = false
                    self.engine.inputNode.removeTap(onBus: 0)
                    self.engine.stop()
                    self.converter = nil
                    self.converterInputFormat = nil
                    Task { @MainActor in
                        self.isRecording = false
                    }
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func applyPreferredInput(in session: AVAudioSession) throws {
        let inputs = session.availableInputs ?? []
        let inputToApply: AVAudioSessionPortDescription?

        if let preferredInput {
            inputToApply = inputs.first { $0.uid == preferredInput.uid }
        } else if let routeInput = session.currentRoute.inputs.first {
            inputToApply = inputs.first { $0.uid == routeInput.uid } ?? inputs.first
        } else {
            inputToApply = inputs.first
        }

        guard let inputToApply else {
            try session.setPreferredInput(nil)
            return
        }

        try session.setPreferredInput(inputToApply)
        self.preferredInput = inputToApply
    }

    func stopRecording() async {
        guard isRecording else { return }
        isRecording = false

        await withCheckedContinuation { cont in
            audioQueue.async { [weak self] in
                guard let self = self else { cont.resume(returning: ()); return }
                self.recorder?.stop()
                self.recorder = nil
                self.engine.inputNode.removeTap(onBus: 0)
                self.engine.stop()
                self.converter = nil
                self.converterInputFormat = nil
                try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
                cont.resume(returning: ())
            }
        }

        await finalizeTranscription()
    }

    private func configureEngineTap() -> Bool {
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        converter = nil
        converterInputFormat = nil

        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            logger.error(
                "Skipping live transcription tap because input format is invalid. sampleRate=\(inputFormat.sampleRate, privacy: .public), channels=\(inputFormat.channelCount, privacy: .public)"
            )
            return false
        }

        inputNode.installTap(onBus: 0, bufferSize: 2_048, format: inputFormat) { [weak self] buffer, _ in
            self?.processInputBuffer(buffer, inputFormat: buffer.format)
        }

        return true
    }

    private func processInputBuffer(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) {
        guard isRecording || recorder != nil else { return }
        guard let downsampledBuffer = downsampledBuffer(from: buffer, inputFormat: inputFormat) else { return }
        guard let channelData = downsampledBuffer.floatChannelData?[0] else { return }

        let frameCount = Int(downsampledBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
        guard !samples.isEmpty else { return }

        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.collectedSamples.append(contentsOf: samples)
            self.publishAmplitudes(from: samples)
            self.scheduleTranscriptionIfNeeded(force: false)
        }
    }

    private func downsampledBuffer(from buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let targetFormat else { return nil }
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else { return nil }

        if converter == nil || converterInputFormat != inputFormat {
            converter = AVAudioConverter(from: inputFormat, to: targetFormat)
            converterInputFormat = inputFormat
        }

        guard let converter else { return nil }

        let ratio = targetFormat.sampleRate / inputFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            return nil
        }

        var didProvideInput = false
        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }

            didProvideInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        guard conversionError == nil else { return nil }
        guard status == .haveData || outputBuffer.frameLength > 0 else { return nil }
        return outputBuffer
    }

    private func publishAmplitudes(from samples: [Float]) {
        let bandsCount = amplitudes.count
        guard bandsCount > 0 else { return }

        let rms = sqrt(samples.reduce(0) { $0 + ($1 * $1) } / Float(samples.count))
        let base = max(0.0, min(1.0, rms * recordingMeterGain))

        var bandValues = [Float](repeating: 0, count: bandsCount)
        for band in 0..<bandsCount {
            let normalizedIdx = Float(band) / Float(max(1, bandsCount - 1))
            let sinValue = sin(normalizedIdx * .pi)
            let jitter = Float.random(in: 0.5..<1.5)
            let value = Float(base) * (sinValue + 0.1) * jitter
            bandValues[band] = value
        }

        DispatchQueue.main.async { [bandValues] in
            self.amplitudes = bandValues
        }
    }

    private func resetRecorderAfterFailedStart(url: URL) {
        recorder?.stop()
        recorder = nil
        fileName = nil
        try? FileManager.default.removeItem(at: url)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func scheduleTranscriptionIfNeeded(force: Bool) {
        guard transcriptionTask == nil else { return }

        let sampleRate = Int(WHISPER_SAMPLE_RATE)
        let chunkSampleCount = Int(transcriptionChunkDuration * Double(sampleRate))
        let minimumFinalChunkSampleCount = Int(minimumFinalChunkDuration * Double(sampleRate))
        let pendingSamples = collectedSamples.count - lastTranscribedSampleIndex

        if !force && pendingSamples < chunkSampleCount {
            return
        }

        if force && pendingSamples < minimumFinalChunkSampleCount {
            return
        }

        let overlapSamples = Int(overlapDuration * Double(sampleRate))
        let chunkStartIndex = max(0, lastTranscribedSampleIndex - overlapSamples)
        let chunkSamples = Array(collectedSamples[chunkStartIndex..<collectedSamples.count])
        let currentSampleIndex = collectedSamples.count

        if !force && rmsLevel(for: chunkSamples) < minimumSpeechRMS {
            lastTranscribedSampleIndex = currentSampleIndex
            return
        }

        let prompt = transcriptionPrompt(from: transcriptionText)

        transcriptionTask = Task { [weak self] in
            guard let self else { return }

            await MainActor.run {
                self.isTranscribing = true
            }

            let transcription = await self.transcriptionService.transcribe(samples: chunkSamples, prompt: prompt)

            await MainActor.run {
                if let transcription, !transcription.isEmpty {
                    self.transcriptionText = self.mergeTranscription(
                        existing: self.transcriptionText,
                        incoming: transcription
                    )
                }

                self.isTranscribing = false
            }

            self.audioQueue.async { [weak self] in
                guard let self = self else { return }
                self.lastTranscribedSampleIndex = currentSampleIndex
                self.transcriptionTask = nil
                if self.isRecording {
                    self.scheduleTranscriptionIfNeeded(force: false)
                }
            }
        }
    }

    private func finalizeTranscription() async {
        await withCheckedContinuation { cont in
            audioQueue.async { [weak self] in
                self?.scheduleTranscriptionIfNeeded(force: true)
                cont.resume(returning: ())
            }
        }

        await transcriptionTask?.value
    }

    private func resetStreamingState() {
        collectedSamples.removeAll(keepingCapacity: true)
        lastTranscribedSampleIndex = 0
        transcriptionTask?.cancel()
        transcriptionTask = nil
        DispatchQueue.main.async {
            self.transcriptionText = ""
            self.isTranscribing = false
            self.amplitudes = Array(repeating: 0, count: self.amplitudes.count)
        }
    }

    private func transcriptionPrompt(from text: String) -> String? {
        let words = text
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        guard words.count >= 3 else { return nil }
        return words.suffix(18).joined(separator: " ")
    }

    private func mergeTranscription(existing: String, incoming: String) -> String {
        let normalizedExisting = normalize(existing)
        let normalizedIncoming = normalize(incoming)

        guard !normalizedIncoming.isEmpty else { return existing }
        guard !normalizedExisting.isEmpty else { return incoming.trimmingCharacters(in: .whitespacesAndNewlines) }

        if normalizedExisting == normalizedIncoming {
            return existing
        }

        if normalizedExisting.hasSuffix(normalizedIncoming) {
            return existing
        }

        if normalizedIncoming.hasPrefix(normalizedExisting) {
            return incoming.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let existingWords = normalizedExisting.split(separator: " ").map(String.init)
        let incomingWords = normalizedIncoming.split(separator: " ").map(String.init)
        let existingOriginalWords = tokenizedWords(from: existing)
        let incomingOriginalWords = tokenizedWords(from: incoming)
        let overlapLimit = min(existingWords.count, incomingWords.count, 24)

        var overlap = 0
        if overlapLimit > 0 {
            for candidate in stride(from: overlapLimit, through: 1, by: -1) {
                let existingTail = existingWords.suffix(candidate)
                let incomingHead = incomingWords.prefix(candidate)
                if existingTail == incomingHead {
                    overlap = candidate
                    break
                }
            }
        }

        if overlap == 0 {
            let incomingTailCount = min(6, incomingWords.count)
            let incomingTail = incomingWords.suffix(incomingTailCount)

            if incomingTailCount > 0, existingWords.suffix(incomingTailCount) == incomingTail {
                return existing
            }
        }

        if overlap > 0, existingOriginalWords.count >= overlap {
            let mergedOriginalWords = existingOriginalWords + incomingOriginalWords.dropFirst(overlap)
            return mergedOriginalWords.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return [existing.trimmingCharacters(in: .whitespacesAndNewlines), incoming.trimmingCharacters(in: .whitespacesAndNewlines)]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(
                of: #"[^\p{L}\p{N}\s]"#,
                with: " ",
                options: .regularExpression
            )
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenizedWords(from text: String) -> [String] {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    private func rmsLevel(for samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let meanSquare = samples.reduce(0) { $0 + ($1 * $1) } / Float(samples.count)
        return sqrt(meanSquare)
    }
}

private actor WhisperTranscriptionService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SmartRecorder", category: "WhisperTranscriptionService")
    private let context: OpaquePointer?
    private let languageCode = "ru"
    private let modelResourceName = "ggml-base"

    init() {
        let modelResourceName = self.modelResourceName

        guard let modelURL = Bundle.main.url(forResource: modelResourceName, withExtension: "bin") else {
            logger.error("Whisper model \(modelResourceName, privacy: .public).bin is missing from the main bundle.")
            context = nil
            return
        }

        var contextParams = whisper_context_default_params()
        contextParams.use_gpu = Self.hasBundledCoreMLModel

        if !Self.hasBundledCoreMLModel {
            logger.notice("Core ML encoder model is missing. Falling back to standard whisper inference without Core ML.")
        }

        context = modelURL.path.withCString { path in
            whisper_init_from_file_with_params(path, contextParams)
        }

        if context == nil {
            logger.error("Failed to initialize whisper context for model at path: \(modelURL.path, privacy: .private)")
        }
    }

    deinit {
        if let context {
            whisper_free(context)
        }
    }

    func transcribe(samples: [Float], prompt: String?) -> String? {
        guard let context, !samples.isEmpty else { return nil }

        var parameters = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        parameters.n_threads = Int32(max(1, ProcessInfo.processInfo.processorCount - 2))
        parameters.offset_ms = 0
        parameters.duration_ms = 0
        parameters.print_progress = false
        parameters.print_realtime = false
        parameters.print_timestamps = false
        parameters.print_special = false
        parameters.no_timestamps = true
        parameters.single_segment = false
        parameters.translate = false
        parameters.detect_language = false
        parameters.no_context = true
        parameters.suppress_blank = true
        parameters.suppress_nst = true

        let promptPointer: UnsafeMutablePointer<CChar>? = prompt.flatMap { strdup($0) }
        parameters.initial_prompt = promptPointer.map { UnsafePointer<CChar>($0) }
        let languagePointer = strdup(languageCode)
        parameters.language = languagePointer.map { UnsafePointer<CChar>($0) }

        defer {
            free(promptPointer)
            free(languagePointer)
        }

        let result = samples.withUnsafeBufferPointer { buffer in
            whisper_full(context, parameters, buffer.baseAddress, Int32(buffer.count))
        }

        guard result == 0 else {
            logger.error("whisper_full failed with code \(result, privacy: .public)")
            return nil
        }

        let segmentsCount = Int(whisper_full_n_segments(context))
        guard segmentsCount > 0 else {
            logger.notice("whisper returned zero text segments for the current chunk.")
            return nil
        }

        let text = (0..<segmentsCount)
            .compactMap { index -> String? in
                guard let segmentText = whisper_full_get_segment_text(context, Int32(index)) else {
                    return nil
                }

                return String(cString: segmentText)
            }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            logger.notice("whisper produced only empty segment text for the current chunk.")
        }

        return text.isEmpty ? nil : text
    }

    private static var hasBundledCoreMLModel: Bool {
        Bundle.main.url(forResource: "ggml-tiny-encoder", withExtension: "mlmodelc") != nil
    }
}
