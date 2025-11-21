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

final class NotesViewModel: ObservableObject {
    @Published var selectedCategory: NoteFolder = .all
    @Published var searchItem: String = String()
    @Published var notes: [Note] = []
    
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
        
        coreDataObserver = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: CoreDataStack.shared.viewContext, queue: .main) { [weak self] _ in
            Task { await self?.loadNotes() }
        }
    }

    private func loadNotes() async {
        let service = NoteEntityService()
        do {
            let notes = try await service.fetch(NoteFetchOptions())
            await MainActor.run { self.notes = notes }
        } catch {
            print("Failed to fetch notes: \(error)")
        }
    }
    
    deinit {
        if let observer = coreDataObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
