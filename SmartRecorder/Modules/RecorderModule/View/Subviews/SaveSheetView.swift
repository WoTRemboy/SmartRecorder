//
//  SaveSheetView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 02.11.2025.
//

import SwiftUI

struct SaveSheetView: View {
    
    @FocusState private var isTitleFocused: Bool
    @EnvironmentObject private var viewModel: RecorderViewModel
    
    internal var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                titleTextField
                folderListLabel
                folderList
                saveButton
                    .padding(.top)
            }
            .padding([.top, .horizontal])
        }
        .scrollDisabled(true)
        .onAppear {
            isTitleFocused = true
        }
    }
    
    private var titleTextField: some View {
        TextField(Texts.RecorderPage.SaveSheet.title, text: $viewModel.saveNoteTitle)
            .focused($isTitleFocused)
            .padding()
            .padding(.horizontal, 10)
            .glassEffect(.regular.tint(Color.BackgroundColors.primary).interactive())
    }
    
    private var folderListLabel: some View {
        Text(Texts.RecorderPage.SaveSheet.folder)
            .font(Font.subheadline())
    }
    
    private var folderList: some View {
        GlassEffectContainer {
            VStack {
                ForEach(NoteFolder.selectCases, id: \.self) { folder in
                    folderView(for: folder)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.saveNoteFolder)
    }
    
    private func folderView(for folder: NoteFolder) -> some View {
        let isSelected = viewModel.isSelectedFolder(folder)
        return HStack {
            Text(folder.title)
                .font(Font.body())
                .foregroundStyle(Color.SupportColors.purple)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isSelected {
                checkmarkIcon
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 22)
        .glassEffect(.regular.tint(isSelected ? Color.BackgroundColors.main : Color.BackgroundColors.primary))
        
        .contentShape(.capsule)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.setSaveFolder(folder)
            }
        }
    }
    
    private var checkmarkIcon: some View {
        Image.RecorderPage.check
            .font(Font.body())
            .foregroundStyle(Color.SupportColors.purple)
            .transition(.scale)
    }
    
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveCurrentNote()
            }
        } label: {
            Text(Texts.RecorderPage.SaveSheet.save)
                .font(Font.largeTitle2(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .frame(height: 56)
        }
        .buttonStyle(.glassProminent)
        .tint(Color.SupportColors.blue)
        
        .disabled(viewModel.saveNoteTitle.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: viewModel.saveNoteTitle.isEmpty)
    }
}

#Preview {
    SaveSheetView()
        .environmentObject(RecorderViewModel())
}
