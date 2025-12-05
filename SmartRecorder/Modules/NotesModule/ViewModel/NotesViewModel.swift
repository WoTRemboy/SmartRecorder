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

private let logger = Logger(subsystem: "SmartRecorder", category: "NotesViewModel")

final class NotesViewModel: ObservableObject {
    
    @Published var selectedCategory: NoteFolder = .all
    @Published var searchItem: String = String()
    @Published var notes: [Note] = []
    @Published var isSyncing: Bool = false
    
    @Published internal var isShowingPlayer = false
    @Published internal var selectedNote: Note? = nil
    
    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private let pageSize: Int = 20
    
    private var coreDataObserver: NSObjectProtocol?

    var filteredAndSearchedAudios: [Note] {
        let categoryFiltered: [Note]
        if selectedCategory == .all {
            categoryFiltered = notes
        } else {
            categoryFiltered = notes.filter { ($0.folderId ?? "") == selectedCategory.rawValue }
        }
        if searchItem.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { $0.title.lowercased().contains(searchItem.lowercased()) }
        }
    }

    init() {
        Task { await self.loadNotes() }
        Task { await self.refresh() }
        
        coreDataObserver = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: CoreDataStack.shared.viewContext, queue: .main) { [weak self] _ in
            Task { await self?.loadNotes() }
        }
    }
    
    internal func toggleIsShowingPlayer() {
        isShowingPlayer.toggle()
    }

    private func loadNotes() async {
        let service = NoteEntityService()
        do {
            let notes = try await service.fetch(NoteFetchOptions())
            logger.debug("Fetched notes from Core Data: count=\(notes.count)")
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
            let page = try await RecordsService.shared.fetchRecords(search: self.searchItem.isEmpty ? nil : self.searchItem, folderId: nil, page: currentPage, size: pageSize)
            await MainActor.run {
                self.totalPages = page.totalPages
                self.isSyncing = false
                logger.info("Sync finished. totalPages=\(self.totalPages)")
            }
        } catch {
            logger.error("Failed to sync records: \(String(describing: error))")
            await MainActor.run { isSyncing = false }
        }
    }

    func loadMoreIfNeeded(currentNote: Note) async {
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
    
    deinit {
        if let observer = coreDataObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

