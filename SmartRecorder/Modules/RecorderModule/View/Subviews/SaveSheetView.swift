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
    @State private var showCancelAlert = false
    
    internal var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                titleTextField
                folderListLabel
                folderList
                actionButtons
                    .padding(.top)
            }
            .padding([.top, .horizontal])
        }
        .scrollDisabled(true)
        .onAppear {
            isTitleFocused = true
        }
        .alert(Texts.RecorderPage.SaveSheet.CancelAlert.title, isPresented: $showCancelAlert) {
            Button(Texts.RecorderPage.SaveSheet.CancelAlert.keep, role: .cancel) {}
            Button(Texts.RecorderPage.SaveSheet.CancelAlert.discard, role: .destructive) {
                viewModel.cancelCurrentNoteSave()
            }
        } message: {
            Text(Texts.RecorderPage.SaveSheet.CancelAlert.message)
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
                .foregroundStyle(Color.LabelColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isSelected {
                checkmarkIcon
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 22)
        .glassEffect(.regular.tint(isSelected ? Color.BackgroundColors.card : Color.BackgroundColors.primary))
        
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

    private var actionButtons: some View {
        HStack(spacing: 10) {
            cancelButton
            saveButton
        }
    }

    private var cancelButton: some View {
        Button(role: .destructive) {
            showCancelAlert = true
        } label: {
            Text(Texts.RecorderPage.SaveSheet.cancel)
                .font(Font.largeTitle3(.semibold))
                .padding(.horizontal)
                .frame(height: 46)
        }
        .buttonStyle(.glass)
        .tint(Color.SupportColors.red)
    }
    
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveCurrentNote()
            }
        } label: {
            Text(Texts.RecorderPage.SaveSheet.save)
                .font(Font.largeTitle3(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .frame(height: 46)
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
