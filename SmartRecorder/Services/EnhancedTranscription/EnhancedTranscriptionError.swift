//
//  EnhancedTranscriptionError.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 04/24/2025.
//

import Foundation

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
