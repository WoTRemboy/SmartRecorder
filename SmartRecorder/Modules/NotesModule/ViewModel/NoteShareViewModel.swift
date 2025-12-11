//
//  NoteShareViewModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 29/11/2025.
//

import Foundation
import SwiftUI
import OSLog
import Combine
import AVFoundation

private let logger = Logger(subsystem: "com.transono.recorder", category: "NoteShareVM")

final class NoteShareViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var shareURL: URL? = nil
    @Published var isPresentingShare: Bool = false
    @Published var errorMessage: String? = nil

    private let note: Note
    
    enum ShareType {
        case pdf, audio
    }

    init(note: Note) {
        self.note = note
    }

    internal func sharePDF() {
        Task {
            await downloadAndPresent(type: .pdf)
        }
        
    }
    
    internal func shareAudio() {
        Task {
            await downloadAndPresent(type: .audio)
        }
    }
    
    internal func downloadAudio() {
        Task {
            do {
                _ = try await downloadAudio(manageLoading: false)
                Toast.shared.present(title: "\(Texts.NotesPage.loadSuccessFirst) \"\(note.title)\" \(Texts.NotesPage.loadSuccessSecond)")
            } catch(let error) {
                Toast.shared.present(title: "\(Texts.NotesPage.loadError) \"\(note.title)\"")
                logger.error("Downloading audio failed: \(error)")
            }
        }
    }

    @MainActor
    private func setLoading(_ value: Bool) { self.isLoading = value }
    
    // MARK: - Direct Downloads
    
    /// Downloads the PDF for the current note and returns a local file URL.
    private func downloadPDF() async throws -> URL {
        guard let sid = note.serverId, let recordId = Int64(sid) else {
            throw NSError(domain: "NoteShareViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Нет serverId для записи"])
        }
        LoadingOverlay.shared.show()
        return try await RecordsService.shared.downloadRecordPDF(recordId: recordId)
    }

    /// Downloads the audio for the current note and returns a local file URL.
    /// - Parameter manageLoading: When true, this method will toggle `isLoading` automatically.
    private func downloadAudio(manageLoading: Bool = true) async throws -> URL {
        if manageLoading {
            await MainActor.run { self.isLoading = true }
            LoadingOverlay.shared.show()
        }
        defer {
            if manageLoading {
                Task { @MainActor in self.isLoading = false }
                LoadingOverlay.shared.hide()
            }
        }
        guard let sid = note.serverId, let recordId = Int64(sid) else {
            throw NSError(domain: "NoteShareViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Нет serverId для записи"])
        }
        return try await RecordsService.shared.downloadRecordAudio(recordId: recordId)
    }

    private func downloadAndPresent(type: ShareType) async {
        setLoading(true)
        do {
            let url: URL
            switch type {
            case .pdf:
                url = try await downloadPDF()
            case .audio:
                url = try await downloadAudio()
            }
            await MainActor.run {
                self.shareURL = url
                self.isLoading = false
                LoadingOverlay.shared.hide()
                self.isPresentingShare = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                LoadingOverlay.shared.hide()
            }
            logger.error("Share download failed: \(String(describing: error), privacy: .private)")
        }
    }

    // MARK: - Duration Helpers
    
    internal func getAudioDuration(for note: Note) -> TimeInterval? {
        if let seconds = note.duration, seconds != -9 {
            return TimeInterval(seconds)
        }
        guard let path = note.audioPath else { return nil }
        let url = URL(fileURLWithPath: path)
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player.duration
        } catch {
            logger.error("Failed to get audio duration: \(String(describing: error))")
            return nil
        }
    }

    internal func formatDuration(_ interval: TimeInterval?) -> String {
        guard let interval = interval else { return "--:--" }
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
