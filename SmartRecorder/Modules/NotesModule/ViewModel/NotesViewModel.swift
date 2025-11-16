//
//  AudioViewModel.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 30.10.2025.
//

import Foundation
import SwiftUI
import Combine

final class NotesViewModel: ObservableObject {
    @Published var selectedCategory: NoteFolder = .all
    @Published var searchItem: String = String()
    
    @Published var audios: [NoteLocal] = allAudios
    
    var filteredAndSearchedAudios: [NoteLocal] {
        let categoryFiltered: [NoteLocal]
        if selectedCategory == .all {
            categoryFiltered = audios
        } else {
            categoryFiltered = audios.filter { $0.category == selectedCategory.rawValue }
        }

        if searchItem.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter {
                $0.headline.lowercased().contains(searchItem.lowercased())
            }
        }
    }
}

