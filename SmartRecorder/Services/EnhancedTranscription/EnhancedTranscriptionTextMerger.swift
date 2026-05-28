//
//  EnhancedTranscriptionTextMerger.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 04/24/2025.
//

import Foundation

enum EnhancedTranscriptionTextMerger {
    static func transcriptionPrompt(from text: String) -> String? {
        let words = text
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        guard words.count >= 3 else { return nil }
        return words.suffix(24).joined(separator: " ")
    }

    static func merge(existing: String, incoming: String) -> String {
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

    private static func normalize(_ text: String) -> String {
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

    private static func tokenizedWords(from text: String) -> [String] {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }
}
