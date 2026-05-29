//
//  AudioViewModel.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 30.10.2025.
//

import Foundation
import SwiftUI
import Combine
import CoreData
import OSLog
import CoreLocation

private let logger = Logger(subsystem: "SmartRecorder", category: "NotesViewModel")

final class NotesViewModel: ObservableObject {
    enum NotesScope: String, CaseIterable, Identifiable {
        case owned
        case shared

        var id: String { rawValue }

        var title: String {
            switch self {
            case .owned:
                return Texts.NotesPage.Scope.owned
            case .shared:
                return Texts.NotesPage.Scope.shared
            }
        }
    }
    
    @Published var selectedCategory: NoteFolder = .all
    @Published var selectedScope: NotesScope = .owned
    @Published var searchItem: String = String()
    @Published var notes: [Note] = []
    @Published var sharedRecords: [SharedRecordResponse] = []
    @Published var isSyncing: Bool = false
    
    @Published internal var isShowingPlayer = false
    @Published internal var selectedNote: Note? = nil
    
    @Published var resolvedPlaceNames: [UUID: (street: String?, city: String?)] = [:]
    @Published private(set) var enhancingNoteIDs: Set<UUID> = []
    @Published private(set) var recentlyEnhancedNoteIDs: Set<UUID> = []
    @Published var enhancementErrorMessage: String? = nil
    
    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private let pageSize: Int = 20
    private let enhancedTranscriptionService = EnhancedTranscriptionService.shared
    private var enhancementTasks: [UUID: Task<Void, Never>] = [:]
    
    private var cancellables = Set<AnyCancellable>()

    var filteredAndSearchedAudios: [Note] {
        let sourceNotes = selectedScope == .owned ? notes : sharedRecords.map { Self.note(from: $0.record) }
        let categoryFiltered: [Note]
        if selectedCategory == .all {
            categoryFiltered = sourceNotes
        } else {
            categoryFiltered = sourceNotes.filter { ($0.folderId ?? "") == selectedCategory.rawValue }
        }
        if searchItem.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { $0.title.lowercased().contains(searchItem.lowercased()) }
        }
    }
    
    internal func placeCity(for note: Note) -> String? {
        return resolvedPlaceNames[note.id]?.city
    }

    internal func placeStreet(for note: Note) -> String? {
        return resolvedPlaceNames[note.id]?.street
    }
    
    internal func fetchPlaceNamesIfNeeded(for note: Note) async {
        if let loc = note.location, (loc.cityName != nil && loc.streetName != nil) {
            return
        }
        if resolvedPlaceNames[note.id]?.city != nil || resolvedPlaceNames[note.id]?.street != nil {
            return
        }
        do {
            if let loc = note.location {
                let cl = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
                let names = try await LocationService.shared.reverseGeocode(location: cl)
                await MainActor.run { self.resolvedPlaceNames[note.id] = names }
            } else if let names = await LocationService.shared.fetchCurrentPlaceNames() {
                await MainActor.run { self.resolvedPlaceNames[note.id] = names }
            }
        } catch(let error) {
            logger.error("Location lookup failed: \(error)")
        }
    }

    init() {
        Task { await self.loadNotes() }
        Task { await self.refresh() }
        
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                let viewContext = CoreDataStack.shared.viewContext
                if let context = notification.object as? NSManagedObjectContext, context != viewContext {
                    viewContext.mergeChanges(fromContextDidSave: notification)
                }
                Task { await self?.loadNotes() }
            }
            .store(in: &cancellables)
    }
    
    internal func toggleIsShowingPlayer() {
        isShowingPlayer.toggle()
    }

    internal func note(withID id: UUID) -> Note? {
        notes.first(where: { $0.id == id })
    }

    internal func isEnhancing(noteID: UUID) -> Bool {
        enhancingNoteIDs.contains(noteID)
    }

    internal func wasRecentlyEnhanced(noteID: UUID) -> Bool {
        recentlyEnhancedNoteIDs.contains(noteID)
    }

    internal func accessRole(for note: Note) -> RecordAccessRole {
        guard selectedScope == .shared, let serverId = note.serverId else {
            return .owner
        }
        return sharedRecords.first { String($0.record.id) == serverId }?.role ?? .viewer
    }

    internal func loadNotes() async {
        let service = NoteEntityService.shared
        do {
            let notes = try await service.fetch(NoteFetchOptions())
            await MainActor.run { self.notes = notes }
        } catch {
            logger.error("Failed to fetch notes: \(String(describing: error))")
        }
    }
    
    @MainActor
    func resetPagination() {
        currentPage = 0
        totalPages = 1
    }

    func refresh() async {
        await MainActor.run { isSyncing = true }
        await MainActor.run { resetPagination() }
        do {
            if await MainActor.run(resultType: NotesScope.self, body: { self.selectedScope }) == .owned {
                let page = try await RecordsService.shared.fetchRecords(search: self.searchItem.isEmpty ? nil : self.searchItem, folderId: nil, page: currentPage, size: pageSize)
                await MainActor.run {
                    self.totalPages = page.totalPages
                    self.isSyncing = false
                    logger.info("Sync finished. totalPages=\(self.totalPages)")
                }
            } else {
                let shared = try await RecordsService.shared.fetchSharedRecords()
                await MainActor.run {
                    self.sharedRecords = shared
                    self.totalPages = 1
                    self.isSyncing = false
                    logger.info("Shared records sync finished. count=\(shared.count)")
                }
            }
        } catch {
            logger.error("Failed to sync records: \(String(describing: error))")
            await MainActor.run { isSyncing = false }
        }
    }

    func loadMoreIfNeeded(currentNote: Note) async {
        if await MainActor.run(resultType: NotesScope.self, body: { self.selectedScope }) == .shared { return }
        if isSyncing || currentPage + 1 >= totalPages { return }
        // Load next page only when current note is the last rendered
        guard let last = await MainActor.run(resultType: Note?.self, body: { self.filteredAndSearchedAudios.last }) else { return }
        if last.id != currentNote.id { return }

        await MainActor.run { isSyncing = true }
        do {
            let page = try await RecordsService.shared.fetchRecords(search: self.searchItem.isEmpty ? nil : self.searchItem, folderId: nil, page: currentPage + 1, size: pageSize)
            await MainActor.run {
                self.currentPage += 1
                self.totalPages = page.totalPages
                self.isSyncing = false
                logger.info("Loaded page. currentPage=\(self.currentPage) totalPages=\(self.totalPages)")
            }
        } catch {
            logger.error("Failed to load next page: \(String(describing: error))")
            await MainActor.run { self.isSyncing = false }
        }
    }

    @MainActor
    func startEnhancement(for note: Note) {
        let currentNote = self.note(withID: note.id) ?? note
        logger.info("Enhanced translation requested for note id=\(currentNote.id.uuidString, privacy: .public) title=\(currentNote.title, privacy: .private)")

        guard !enhancingNoteIDs.contains(currentNote.id) else { return }
        guard let audioURL = Self.resolveAudioURL(for: currentNote.audioPath) else {
            logger.error("Enhanced translation aborted: audio URL is missing for note id=\(currentNote.id.uuidString, privacy: .public) audioPath=\(String(describing: currentNote.audioPath), privacy: .private)")
            enhancementErrorMessage = Texts.NotesPage.Enhancement.Errors.audioMissing
            return
        }

        logger.info("Enhanced translation audio URL resolved for note id=\(currentNote.id.uuidString, privacy: .public) path=\(audioURL.path, privacy: .private)")

        enhancementErrorMessage = nil
        recentlyEnhancedNoteIDs.remove(currentNote.id)
        enhancingNoteIDs.insert(currentNote.id)
        enhancementTasks[currentNote.id]?.cancel()

        enhancementTasks[currentNote.id] = Task { [weak self] in
            guard let self else { return }

            do {
                let transcription = try await self.enhancedTranscriptionService.transcribeAudioFile(at: audioURL)
                try Task.checkCancellation()
                logger.info("Enhanced translation completed whisper pass for note id=\(currentNote.id.uuidString, privacy: .public) textLength=\(transcription.count, privacy: .public)")

                var updatedNote = currentNote
                updatedNote.transcription = transcription.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).nilIfEmpty
                updatedNote.updatedAt = .now

                let savedNote = try await NoteEntityService.shared.upsert(updatedNote)
                try Task.checkCancellation()
                logger.info("Enhanced translation saved updated note id=\(currentNote.id.uuidString, privacy: .public)")

                await MainActor.run {
                    self.replaceStoredNote(with: savedNote)
                    self.recentlyEnhancedNoteIDs.insert(currentNote.id)
                    self.finishEnhancementTask(for: currentNote.id)
                }

                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(2.2))
                    self?.recentlyEnhancedNoteIDs.remove(currentNote.id)
                }
            } catch is CancellationError {
                logger.info("Enhanced translation cancelled for note id=\(currentNote.id.uuidString, privacy: .public)")
                await MainActor.run {
                    self.finishEnhancementTask(for: currentNote.id)
                }
            } catch {
                logger.error("Enhanced translation failed for note id=\(currentNote.id.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)")
                await MainActor.run {
                    self.enhancementErrorMessage = (error as? LocalizedError)?.errorDescription ?? Texts.NotesPage.Enhancement.Errors.transcriptionFailed
                    self.finishEnhancementTask(for: currentNote.id)
                }
            }
        }
    }

    @MainActor
    func cancelEnhancement(for noteID: UUID) {
        logger.info("Enhanced translation cancel requested for note id=\(noteID.uuidString, privacy: .public)")
        enhancementTasks[noteID]?.cancel()
        finishEnhancementTask(for: noteID)
    }

    @MainActor
    func dismissEnhancementError() {
        enhancementErrorMessage = nil
    }

    @MainActor
    private func replaceStoredNote(with note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }

        if selectedNote?.id == note.id {
            selectedNote = note
        }
    }

    @MainActor
    private func finishEnhancementTask(for noteID: UUID) {
        enhancingNoteIDs.remove(noteID)
        enhancementTasks[noteID] = nil
    }

    private static func resolveAudioURL(for audioPath: String?) -> URL? {
        guard let audioPath, !audioPath.isEmpty else { return nil }

        let trimmed = audioPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("/") || trimmed.hasPrefix("file://") {
            if trimmed.hasPrefix("file://") {
                return URL(string: trimmed)
            }

            return URL(fileURLWithPath: trimmed)
        }

        return AudioRecorderService.url(forFileName: trimmed)
    }

    private static func note(from record: RecordResponse) -> Note {
        let location: Location? = {
            if let latitude = record.latitude, let longitude = record.longitude {
                return Location(latitude: latitude, longitude: longitude, cityName: nil, streetName: nil)
            }
            return nil
        }()

        let stableID = UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012lld", record.id))") ?? UUID()

        return Note(
            id: stableID,
            serverId: String(record.id),
            folderId: record.category,
            title: record.title ?? "",
            transcription: record.description,
            audioPath: nil,
            createdAt: record.createdAt ?? record.datetime ?? Date(),
            updatedAt: record.updatedAt ?? record.datetime ?? Date(),
            duration: record.duration.map(Int.init),
            location: location
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
