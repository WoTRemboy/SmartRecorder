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
        VStack {
            PickerView(selectedCategory: $viewModel.selectedCategory)
                .padding(.bottom, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(viewModel.filteredAndSearchedAudios) { note in
                    noteCardView(note: note)
                }
            }
        }
        .padding(.horizontal)
        .navigationTitle(Texts.NotesPage.title)
        .searchable(text: $viewModel.searchItem,
                    placement: .toolbarPrincipal,
                    prompt: Texts.NotesPage.search)
        .background(Color.BackgroundColors.primary)
    }
    
    private func noteCardView(note: Note) -> some View {
        NoteCardView(audio: note)
            .onTapGesture {
                appRouter.push(.notesList, in: .notes)
            }
    }
}

#Preview {
    NavigationStack {
        NotesListView()
            .environmentObject(AppRouter())
    }
}
