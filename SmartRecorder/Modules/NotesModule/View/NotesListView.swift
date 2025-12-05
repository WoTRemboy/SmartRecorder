//
//  NotesListView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI


struct NotesListView: View {
    
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var viewModel: NotesViewModel
    @Namespace private var namespace
    
    internal var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            pickerView
            if viewModel.filteredAndSearchedAudios.isEmpty {
                VStack(spacing: 16) {
                    Image.NotesPage.empty
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .foregroundStyle(.secondary)
                    Text(Texts.NotesPage.empty)
                        .font(.title2())
                        .foregroundStyle(Color.LabelColors.secondary)
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
        .animation(.spring(duration: 0.3, bounce: 0.2), value: viewModel.filteredAndSearchedAudios.isEmpty)
        
        .navigationTitle(Texts.NotesPage.title)
        .toolbarRole(.navigationStack)
        .fullScreenCover(item: $viewModel.selectedNote) { item in
            PlayerScreenView(note: item, namespace: namespace)
        }
        
        .searchable(text: $viewModel.searchItem,
                    placement: .toolbarPrincipal,
                    prompt: Texts.NotesPage.search)
        
        .onChange(of: viewModel.searchItem) { _, _ in
            Task { await viewModel.refresh() }
        }
        .refreshable { await viewModel.refresh() }
    }
    
    private var pickerView: some View {
        PickerView(selectedCategory: $viewModel.selectedCategory)
            .padding(.top, 8)
            .padding(.horizontal)
            .onChange(of: viewModel.selectedCategory) { _, _ in
                Task { await viewModel.refresh() }
            }
    }
    
    private func noteCardView(note: Note) -> some View {
        NoteCardView(note: note, namespace: namespace, viewModel: viewModel)
            .onTapGesture {
                appRouter.push(.noteDetails(note: note, namespace: namespace, viewModel: viewModel), in: .notes)
            }
            .padding(.horizontal)
            .transition(.blurReplace)
            .task { await viewModel.loadMoreIfNeeded(currentNote: note) }
    }
}

#Preview {
    NavigationStack {
        NotesListView()
            .environmentObject(AppRouter())
            .environmentObject(NotesViewModel())
    }
}
