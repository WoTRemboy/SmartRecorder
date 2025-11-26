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
            if viewModel.filteredAndSearchedAudios.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .foregroundStyle(.secondary)
                    Text("Нет записей")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredAndSearchedAudios) { note in
                        noteCardView(note: note)
                    }
                }
                .padding(.top)
                .animation(.spring(duration: 0.3, bounce: 0.2), value: viewModel.filteredAndSearchedAudios)
            }
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
    
    private func noteCardView(note: Note) -> some View {
        NoteCardView(note: note)
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
