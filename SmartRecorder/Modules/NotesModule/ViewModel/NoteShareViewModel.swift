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
                _ = try await downloadAudioForPlayback(manageLoading: false)
                Toast.shared.present(title: "\(Texts.NotesPage.loadSuccessFirst) \"\(note.title)\" \(Texts.NotesPage.loadSuccessSecond)")
            } catch(let error) {
                Toast.shared.present(title: "\(Texts.NotesPage.loadError) \"\(note.title)\"")
                logger.error("Downloading audio failed: \(error)")
            }
        }
    }

    internal func downloadAudioForPlayback(manageLoading: Bool = true) async throws -> URL {
        try await downloadAudio(manageLoading: manageLoading)
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
        if let seconds = note.duration, seconds > 0, seconds != -9 {
            return TimeInterval(seconds)
        }
        guard let url = Self.resolveAudioURL(for: note.audioPath) else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player.duration
        } catch {
            logger.error("Failed to get audio duration: \(String(describing: error))")
            return nil
        }
    }

    private static func resolveAudioURL(for audioPath: String?) -> URL? {
        guard let audioPath, !audioPath.isEmpty else { return nil }

        let trimmed = audioPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("file://") {
            return URL(string: trimmed)
        }

        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }

        return AudioRecorderService.url(forFileName: trimmed)
    }

    internal func formatDuration(_ interval: TimeInterval?) -> String {
        guard let interval = interval else { return "--:--" }
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

@MainActor
final class RecordDetailsViewModel: ObservableObject {
    @Published var record: RecordResponse?
    @Published var statuses: [ProcessingStatusResponse] = []
    @Published var summary: RecordSummaryResponse?
    @Published var sharedUsers: [SharedRecordUserResponse] = []
    @Published var shareEmail: String = ""
    @Published var selectedRole: RecordAccessRole = .viewer
    @Published var isLoadingDetails: Bool = false
    @Published var isSharing: Bool = false
    @Published var errorMessage: String?

    private let recordId: Int64?
    private var pollingTask: Task<Void, Never>?

    init(recordId: Int64?) {
        self.recordId = recordId
    }

    deinit {
        pollingTask?.cancel()
    }

    var canLoadRemoteDetails: Bool {
        recordId != nil
    }

    var transcriptionStatus: ProcessingStatusResponse? {
        statuses.first { $0.stage == .transcription }
    }

    var summarizationStatus: ProcessingStatusResponse? {
        statuses.first { $0.stage == .summarization }
    }

    var shouldPollSummary: Bool {
        guard let status = summarizationStatus?.status else {
            return recordId != nil && summary == nil
        }
        return status == .pending || status == .inProgress
    }

    func load() {
        guard recordId != nil else { return }
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            await self?.loadOnce()
            await self?.startPollingIfNeeded()
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func addShare() {
        let trimmedEmail = shareEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, let recordId else { return }

        isSharing = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                try await RecordsService.shared.shareRecord(recordId: recordId, email: trimmedEmail, userId: nil, role: selectedRole)
                let users = try await RecordsService.shared.fetchSharedUsers(recordId: recordId)
                self.sharedUsers = users
                self.shareEmail = ""
                self.isSharing = false
                Toast.shared.present(title: Texts.NotesPage.Sharing.shareSuccess)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isSharing = false
            }
        }
    }

    func revokeAccess(for user: SharedRecordUserResponse) {
        guard let recordId else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await RecordsService.shared.revokeSharedUser(recordId: recordId, userId: user.userId)
                self.sharedUsers.removeAll { $0.userId == user.userId }
                Toast.shared.present(title: Texts.NotesPage.Sharing.revokeSuccess)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func loadOnce() async {
        guard let recordId else { return }

        isLoadingDetails = true
        errorMessage = nil

        do {
            async let recordRequest = RecordsService.shared.fetchRecord(recordId: recordId)
            async let sharedUsersRequest = RecordsService.shared.fetchSharedUsers(recordId: recordId)
            let loadedRecord = try await recordRequest
            record = loadedRecord
            statuses = loadedRecord.statuses
            summary = loadedRecord.summary
            sharedUsers = (try? await sharedUsersRequest) ?? []
            isLoadingDetails = false
        } catch {
            errorMessage = error.localizedDescription
            isLoadingDetails = false
        }
    }

    private func refreshProcessingState() async {
        guard let recordId else { return }

        do {
            let loadedRecord = try await RecordsService.shared.fetchRecord(recordId: recordId)
            record = loadedRecord
            statuses = loadedRecord.statuses
            summary = loadedRecord.summary
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startPollingIfNeeded() async {
        while shouldPollSummary && !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await refreshProcessingState()
        }
    }
}
