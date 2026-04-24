//
//  EnhancedTranscriptionService.swift
//  SmartRecorder
//
//  Created by OpenAI Codex on 18.11.2025.
//

import Foundation
@preconcurrency import AVFoundation
import OSLog
import whisper

enum EnhancedTranscriptionError: LocalizedError {
    case missingAudioFile
    case missingModel(String)
    case failedToReadAudio
    case failedToInitializeModel
    case transcriptionFailed(Int32)
    case emptyTranscription

    var errorDescription: String? {
        switch self {
        case .missingAudioFile:
            return Texts.NotesPage.Enhancement.Errors.audioMissing
        case .missingModel:
            return Texts.NotesPage.Enhancement.Errors.modelMissing
        case .failedToReadAudio:
            return Texts.NotesPage.Enhancement.Errors.audioReadFailed
        case .failedToInitializeModel:
            return Texts.NotesPage.Enhancement.Errors.modelLoadFailed
        case let .transcriptionFailed(code):
            return "\(Texts.NotesPage.Enhancement.Errors.transcriptionFailed) (\(code))"
        case .emptyTranscription:
            return Texts.NotesPage.Enhancement.Errors.emptyTranscription
        }
    }
}

actor EnhancedTranscriptionService {
    static let shared = EnhancedTranscriptionService()
    private static let modelResourceName = "ggml-large-v3-turbo-q5_0"
    private static let chunkDuration: Double = 20
    private static let overlapDuration: Double = 2

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SmartRecorder",
        category: "EnhancedTranscriptionService"
    )
    private let languageCode = "ru"
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: Double(WHISPER_SAMPLE_RATE),
        channels: 1,
        interleaved: false
    )
    private let context: OpaquePointer?

    private init() {
        let modelResourceName = Self.modelResourceName
        whisper_log_set({ _, text, _ in
            guard let text else { return }
            let message = String(cString: text)

            let suppressedFragments = [
                "The model is not found at URL:",
                "failed to load Core ML model",
                "-encoder.mlmodelc"
            ]

            if suppressedFragments.contains(where: { message.contains($0) }) {
                return
            }

            fputs(message, stderr)
        }, nil)

        guard let modelURL = Bundle.main.url(forResource: modelResourceName, withExtension: "bin") else {
            logger.error("Enhanced whisper model \(modelResourceName, privacy: .public).bin is missing from the main bundle.")
            context = nil
            return
        }

        logger.info("Enhanced whisper init: modelURL=\(modelURL.path, privacy: .private)")

        var contextParams = whisper_context_default_params()
        contextParams.use_gpu = false

        context = modelURL.path.withCString { path in
            whisper_init_from_file_with_params(path, contextParams)
        }

        if context == nil {
            logger.error("Failed to initialize enhanced whisper context for model at path: \(modelURL.path, privacy: .private)")
        } else {
            logger.info("Enhanced whisper context initialized successfully for model=\(modelResourceName, privacy: .public)")
        }
    }

    deinit {
        if let context {
            whisper_free(context)
        }
    }

    func transcribeAudioFile(at url: URL) async throws -> String {
        try Task.checkCancellation()
        logger.info("Enhanced transcription started for file path=\(url.path, privacy: .private)")

        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.error("Enhanced transcription failed: file does not exist at path=\(url.path, privacy: .private)")
            throw EnhancedTranscriptionError.missingAudioFile
        }

        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? NSNumber {
            logger.info("Enhanced transcription audio file size bytes=\(size.int64Value, privacy: .public)")
        }

        let modelResourceName = Self.modelResourceName
        guard Bundle.main.url(forResource: modelResourceName, withExtension: "bin") != nil else {
            logger.error("Enhanced transcription failed: model resource missing in bundle model=\(modelResourceName, privacy: .public)")
            throw EnhancedTranscriptionError.missingModel(modelResourceName)
        }

        guard let context else {
            logger.error("Enhanced transcription failed: whisper context is nil for model=\(modelResourceName, privacy: .public)")
            throw EnhancedTranscriptionError.failedToInitializeModel
        }

        let samples = try resampledSamples(from: url)
        guard !samples.isEmpty else {
            logger.error("Enhanced transcription failed: resampled audio is empty")
            throw EnhancedTranscriptionError.failedToReadAudio
        }

        try Task.checkCancellation()
        logger.info("Enhanced transcription resampled samples count=\(samples.count, privacy: .public)")

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

        let languagePointer = strdup(languageCode)
        parameters.language = languagePointer.map { UnsafePointer<CChar>($0) }

        defer {
            free(languagePointer)
        }

        let sampleRate = Int(WHISPER_SAMPLE_RATE)
        let chunkSampleCount = Int(Self.chunkDuration * Double(sampleRate))
        let overlapSampleCount = Int(Self.overlapDuration * Double(sampleRate))

        var mergedText = ""
        var startIndex = 0
        var chunkIndex = 0

        logger.info("Enhanced transcription chunking sampleRate=\(sampleRate, privacy: .public) chunkSamples=\(chunkSampleCount, privacy: .public) overlapSamples=\(overlapSampleCount, privacy: .public)")

        while startIndex < samples.count {
            try Task.checkCancellation()
            let endIndex = min(samples.count, startIndex + chunkSampleCount)
            let chunk = Array(samples[startIndex..<endIndex])
            let prompt = transcriptionPrompt(from: mergedText)

            logger.info("Enhanced transcription chunk start index=\(chunkIndex, privacy: .public) range=\(startIndex, privacy: .public)..<\(endIndex, privacy: .public) chunkCount=\(chunk.count, privacy: .public) promptLength=\(prompt?.count ?? 0, privacy: .public)")

            if let chunkText = try transcribeChunk(chunk, context: context, parameters: parameters, prompt: prompt) {
                logger.info("Enhanced transcription chunk success index=\(chunkIndex, privacy: .public) chunkTextLength=\(chunkText.count, privacy: .public) chunkText=\(chunkText, privacy: .private)")

                if mergedText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                    mergedText = chunkText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    logger.info("Enhanced transcription seeded merged text from first non-empty chunk length=\(mergedText.count, privacy: .public)")
                } else {
                    mergedText = mergeTranscription(existing: mergedText, incoming: chunkText)
                    logger.info("Enhanced transcription merged text updated length=\(mergedText.count, privacy: .public)")
                }
            } else {
                logger.notice("Enhanced transcription chunk returned no text index=\(chunkIndex, privacy: .public)")
            }

            if endIndex == samples.count {
                break
            }

            startIndex = max(endIndex - overlapSampleCount, startIndex + 1)
            chunkIndex += 1
        }

        let text = mergedText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !text.isEmpty else {
            logger.error("Enhanced transcription finished with empty merged text rawMerged=\(mergedText, privacy: .private)")
            throw EnhancedTranscriptionError.emptyTranscription
        }

        try Task.checkCancellation()
        logger.info("Enhanced transcription finished successfully finalLength=\(text.count, privacy: .public)")

        return text
    }

    private func transcribeChunk(
        _ samples: [Float],
        context: OpaquePointer,
        parameters: whisper_full_params,
        prompt: String?
    ) throws -> String? {
        guard !samples.isEmpty else { return nil }

        var parameters = parameters
        let promptPointer: UnsafeMutablePointer<CChar>? = prompt.flatMap { strdup($0) }
        parameters.initial_prompt = promptPointer.map { UnsafePointer<CChar>($0) }

        defer {
            free(promptPointer)
        }

        let result = samples.withUnsafeBufferPointer { buffer in
            whisper_full(context, parameters, buffer.baseAddress, Int32(buffer.count))
        }

        guard result == 0 else {
            logger.error("Enhanced whisper_full failed with code \(result, privacy: .public)")
            throw EnhancedTranscriptionError.transcriptionFailed(result)
        }

        let segmentsCount = Int(whisper_full_n_segments(context))
        guard segmentsCount > 0 else {
            logger.notice("Enhanced transcription chunk has zero segments")
            return nil
        }

        logger.info("Enhanced transcription chunk segments count=\(segmentsCount, privacy: .public)")

        let text = (0..<segmentsCount)
            .compactMap { index -> String? in
                guard let segmentText = whisper_full_get_segment_text(context, Int32(index)) else {
                    return nil
                }

                return String(cString: segmentText)
            }
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        return text.isEmpty ? nil : text
    }

    private func resampledSamples(from url: URL) throws -> [Float] {
        guard let targetFormat else {
            throw EnhancedTranscriptionError.failedToReadAudio
        }

        let audioFile = try AVAudioFile(forReading: url)
        let inputFormat = audioFile.processingFormat

        logger.info("Enhanced transcription reading audio inputSampleRate=\(inputFormat.sampleRate, privacy: .public) channels=\(inputFormat.channelCount, privacy: .public)")

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            logger.error("Enhanced transcription failed: could not create AVAudioConverter")
            throw EnhancedTranscriptionError.failedToReadAudio
        }

        let inputFrameCapacity: AVAudioFrameCount = 4_096
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: inputFormat,
            frameCapacity: inputFrameCapacity
        ) else {
            logger.error("Enhanced transcription failed: could not allocate input buffer frameCapacity=\(inputFrameCapacity, privacy: .public)")
            throw EnhancedTranscriptionError.failedToReadAudio
        }

        logger.info("Enhanced transcription input buffer allocated frameCapacity=\(inputFrameCapacity, privacy: .public)")

        var samples: [Float] = []
        var iteration = 0
        let totalFrames = max(Int64(0), audioFile.length)
        var remainingFrames = totalFrames

        logger.info("Enhanced transcription totalFrames=\(totalFrames, privacy: .public)")

        while remainingFrames > 0 {
            let framesToRead = AVAudioFrameCount(min(Int64(inputFrameCapacity), remainingFrames))
            do {
                try audioFile.read(into: inputBuffer, frameCount: framesToRead)
            } catch {
                logger.error("Enhanced transcription audio read failed on iteration=\(iteration, privacy: .public) error=\(String(describing: error), privacy: .public)")
                throw EnhancedTranscriptionError.failedToReadAudio
            }

            if inputBuffer.frameLength == 0 {
                logger.notice("Enhanced transcription audio read returned zero frames before remainingFrames reached zero at iteration=\(iteration, privacy: .public)")
                break
            }

            logger.info("Enhanced transcription read iteration=\(iteration, privacy: .public) requestedFrames=\(framesToRead, privacy: .public) inputFrameLength=\(inputBuffer.frameLength, privacy: .public)")

            let ratio = targetFormat.sampleRate / inputFormat.sampleRate
            let outputFrameCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 32

            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: outputFrameCapacity
            ) else {
                logger.error("Enhanced transcription failed: could not allocate output buffer iteration=\(iteration, privacy: .public) frameCapacity=\(outputFrameCapacity, privacy: .public)")
                throw EnhancedTranscriptionError.failedToReadAudio
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
                return inputBuffer
            }

            if let conversionError {
                logger.error("Enhanced transcription audio conversion failed: \(conversionError.localizedDescription, privacy: .public)")
                throw EnhancedTranscriptionError.failedToReadAudio
            }

            if status == .error {
                logger.error("Enhanced transcription converter returned status=.error without NSError iteration=\(iteration, privacy: .public)")
                throw EnhancedTranscriptionError.failedToReadAudio
            }

            logger.info("Enhanced transcription converter status iteration=\(iteration, privacy: .public) status=\(String(describing: status), privacy: .public) outputFrameLength=\(outputBuffer.frameLength, privacy: .public)")

            guard status == .haveData || outputBuffer.frameLength > 0 else {
                inputBuffer.frameLength = 0
                iteration += 1
                continue
            }

            guard let channelData = outputBuffer.floatChannelData?[0] else {
                logger.error("Enhanced transcription failed: output buffer missing float channel data iteration=\(iteration, privacy: .public)")
                throw EnhancedTranscriptionError.failedToReadAudio
            }

            samples.append(contentsOf: UnsafeBufferPointer(start: channelData, count: Int(outputBuffer.frameLength)))
            remainingFrames -= Int64(inputBuffer.frameLength)
            inputBuffer.frameLength = 0
            iteration += 1
        }

        logger.info("Enhanced transcription audio read finished iterations=\(iteration, privacy: .public) totalSamples=\(samples.count, privacy: .public) remainingFrames=\(remainingFrames, privacy: .public)")

        return samples
    }

    private func transcriptionPrompt(from text: String) -> String? {
        let words = text
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        guard words.count >= 3 else { return nil }
        return words.suffix(24).joined(separator: " ")
    }

    private func mergeTranscription(existing: String, incoming: String) -> String {
        let normalizedExisting = normalize(existing)
        let normalizedIncoming = normalize(incoming)

        guard !normalizedIncoming.isEmpty else { return existing }
        guard !normalizedExisting.isEmpty else { return incoming.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }

        if normalizedExisting == normalizedIncoming || normalizedExisting.hasSuffix(normalizedIncoming) {
            return existing
        }

        if normalizedIncoming.hasPrefix(normalizedExisting) {
            return incoming.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        let existingWords = normalizedExisting.split(separator: " ").map(String.init)
        let incomingWords = normalizedIncoming.split(separator: " ").map(String.init)
        let existingOriginalWords = tokenizedWords(from: existing)
        let incomingOriginalWords = tokenizedWords(from: incoming)
        let overlapLimit = min(existingWords.count, incomingWords.count, 30)

        var overlap = 0
        if overlapLimit > 0 {
            for candidate in stride(from: overlapLimit, through: 1, by: -1) {
                if existingWords.suffix(candidate) == incomingWords.prefix(candidate) {
                    overlap = candidate
                    break
                }
            }
        }

        if overlap > 0, existingOriginalWords.count >= overlap {
            let mergedOriginalWords = existingOriginalWords + incomingOriginalWords.dropFirst(overlap)
            return mergedOriginalWords.joined(separator: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        return [existing.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), incoming.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(
                of: #"[^\\p{L}\\p{N}\\s]"#,
                with: " ",
                options: .regularExpression
            )
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    private func tokenizedWords(from text: String) -> [String] {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }
}
