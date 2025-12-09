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
    
    @Published var selectedCategory: NoteFolder = .all
    @Published var searchItem: String = String()
    @Published var notes: [Note] = []
    @Published var isSyncing: Bool = false
    
    @Published internal var isShowingPlayer = false
    @Published internal var selectedNote: Note? = nil
    
    @Published var resolvedPlaceNames: [UUID: (street: String?, city: String?)] = [:]
    
    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private let pageSize: Int = 20
    
    private var cancellables = Set<AnyCancellable>()

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
}
