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
        ScrollView(.vertical, showsIndicators: false) {
            pickerView
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
        .searchable(text: $viewModel.searchItem,
                    placement: .toolbarPrincipal,
                    prompt: Texts.NotesPage.search)
    }
    
    private var pickerView: some View {
        PickerView(selectedCategory: $viewModel.selectedCategory)
            .padding(.top, 8)
            .padding(.horizontal)
    }
    
    private func noteCardView(note: NoteLocal) -> some View {
        NoteCardView(audio: note)
            .onTapGesture {
                appRouter.push(.noteDetails(note: note), in: .notes)
            }
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
