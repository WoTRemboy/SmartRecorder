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
    @Published var selectedCategory: String = "Все"
    @Published var searchItem: String = ""
    
    @Published var audios: [Note] = allAudios
    
    var filteredAndSearchedAudios: [Note] {
        let categoryFiltered: [Note]
        if selectedCategory == "Все" {
            categoryFiltered = audios
        } else {
            categoryFiltered = audios.filter { $0.category == selectedCategory }
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

