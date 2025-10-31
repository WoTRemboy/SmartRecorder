//
//  AudioViewModel.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 30.10.2025.
//

import Foundation
import SwiftUI
import Combine

final class AudioViewModel: ObservableObject {
    @Published var selectedCategory: String = "Все"
    @Published var searchItem: String = ""
    
    @Published var audios: [Audio] = allAudios
    
    var filteredAndSearchedAudios: [Audio] {
        let categoryFiltered: [Audio]
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

