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

    init(note: Note) {
        self.note = note
    }

    enum ShareType { case pdf, audio }

    func sharePDF() { Task { await downloadAndPresent(type: .pdf) } }
    func shareAudio() { Task { await downloadAndPresent(type: .audio) } }

    @MainActor
    private func setLoading(_ value: Bool) { self.isLoading = value }

    private func downloadAndPresent(type: ShareType) async {
        guard let sid = note.serverId, let recordId = Int64(sid) else {
            await MainActor.run { self.errorMessage = "Нет serverId для записи" }
            return
        }
        setLoading(true)
        do {
            let url: URL
            switch type {
            case .pdf:
                url = try await RecordsService.shared.downloadRecordPDF(recordId: recordId)
            case .audio:
                url = try await RecordsService.shared.downloadRecordAudio(recordId: recordId)
            }
            await MainActor.run {
                self.shareURL = url
                self.isPresentingShare = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
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
