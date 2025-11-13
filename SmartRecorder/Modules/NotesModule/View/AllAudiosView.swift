//
//  ContentView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI


struct NotesListView: View {
    
    @StateObject private var viewModel = AudioViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                PickerView(selectedCategory: $viewModel.selectedCategory)
                    .padding(.bottom, 20)
                
                ScrollView {
                    ForEach(viewModel.filteredAndSearchedAudios) { audio in
                        NavigationLink(destination:
                                        SingleAudioDescriptionView(audio: audio)) {
                            AudioCardView(audio: audio)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .padding(.bottom, -20)
            }
            .padding(20)
            .navigationTitle("Мои записи")
            .searchable(text: $viewModel.searchItem,
                        placement: .navigationBarDrawer,
                        prompt: "Поиск")
            .background(Color.BackgroundColors.primary)
        }
    }
}

#Preview {
    NotesListView()
}
