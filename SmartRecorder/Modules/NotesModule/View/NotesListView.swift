//
//  NotesListView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI


struct NotesListView: View {
    
    @EnvironmentObject private var appRouter: AppRouter
    @StateObject private var viewModel = NotesViewModel()
    
    internal var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredAndSearchedAudios) { note in
                    noteCardView(note: note)
                }
            }
            .padding(.top)
            .animation(.bouncy(duration: 0.3), value: viewModel.filteredAndSearchedAudios)
        }
        .background(Color.BackgroundColors.primary)
        .navigationTitle(Texts.NotesPage.title)
        .toolbarRole(.navigationStack)
        .toolbar {
            ToolbarItem(placement: .largeSubtitle) {
                PickerView(selectedCategory: $viewModel.selectedCategory)
                    .padding(.top)
            }
        }
        .searchable(text: $viewModel.searchItem,
                    placement: .toolbarPrincipal,
                    prompt: Texts.NotesPage.search)
    }
    
    private func noteCardView(note: Note) -> some View {
        NavigationLink(destination: {
            SingleAudioDescriptionView(audio: note)
        }, label: {
            NoteCardView(audio: note)
        })
        .padding(.horizontal)
        .transition(.blurReplace)
    }
}

#Preview {
    NavigationStack {
        NotesListView()
            .environmentObject(AppRouter())
    }
}
