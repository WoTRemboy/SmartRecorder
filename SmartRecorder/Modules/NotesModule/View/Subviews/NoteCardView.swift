//
//  NoteCardView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI

struct NoteCardView: View {
    
    @ObservedObject internal var viewModel: NotesViewModel
    @StateObject private var shareVM: NoteShareViewModel
    
    @State private var isEditing = false
    @State private var isShowingPlayer = false
    
    private let note: Note
    private let namespace: Namespace.ID
    
    init(note: Note, namespace: Namespace.ID, viewModel: NotesViewModel) {
        self.note = note
        self.namespace = namespace
        self.viewModel = viewModel
        _shareVM = StateObject(wrappedValue: NoteShareViewModel(note: note))
    }
    
    internal var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleStack
            descriptionLabel
            bottomStack
        }
        .padding(.vertical)
        .padding(.horizontal, 24)
        .background(Color.BackgroundColors.main)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $shareVM.isPresentingShare, onDismiss: { shareVM.shareURL = nil }) {
            if let url = shareVM.shareURL {
                ActivityView(activityItems: [url])
                    .ignoresSafeArea()
            }
        }
        .alert(Texts.NotesPage.error,
               isPresented: .constant(shareVM.errorMessage != nil),
               actions: {
            Button(Texts.NotesPage.ok) {
                shareVM.errorMessage = nil
            }
        }, message: {
            Text(shareVM.errorMessage ?? "")
        })
        .matchedTransitionSource(id: note.id, in: namespace)
    }
    
    private var titleStack: some View {
        HStack {
            Text(note.title)
                .font(.subheadline())
                .foregroundStyle(Color.LabelColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            shareMenu
        }
    }
    
    private var descriptionLabel: some View {
        Text(note.transcription ?? Texts.NotesPage.inProgress)
            .lineLimit(2)
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .foregroundStyle(Color.LabelColors.secondary)
            .padding(.bottom, 16)
    }
    
    private var bottomStack: some View {
        GlassEffectContainer {
            HStack(alignment: .bottom) {
                ChipsView(text: DateService.formattedDate(note.createdAt))
                ChipsView(text: DateService.formattedTime(note.createdAt))
                
                Spacer()
                playButton
            }
        }
    }
    
    private var playButton: some View {
        Button {
            playButtonAction()
        } label: {
            playButtonImage
                .frame(width: 64, height: 64)
                .foregroundStyle(Color.SupportColors.blue)
                .glassEffect(.regular.interactive())
        }
        .disabled(shareVM.isLoading)
        .symbolEffect(.breathe, isActive: shareVM.isLoading)
    }
    
    private var playButtonImage: some View {
        if isValidAudioPath {
            return Image.NotesPage.play
                .resizable()
        } else {
            return Image.NotesPage.download
                .resizable()
        }
    }
    
    private func playButtonAction() {
        if isValidAudioPath {
            viewModel.selectedNote = note
        } else {
            shareVM.downloadAudio()
        }
    }
    
    private var shareMenu: some View {
        Menu {
            sharePDFButton
            shareAudioButton
        } label: {
            Image.NotesPage.share
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(Color.SupportColors.blue)
        }
    }
    
    private var sharePDFButton: some View {
        Button {
            shareVM.sharePDF()
        } label: {
            Label {
                Text(Texts.NotesPage.pdf)
            } icon: {
                Image.NotesPage.pdf
            }
        }
    }
    
    private var shareAudioButton: some View {
        Button {
            shareVM.shareAudio()
        } label: {
            Label {
                Text(Texts.NotesPage.audio)
            } icon: {
                Image.NotesPage.audio
            }
        }
    }
    
    private var isValidAudioPath: Bool {
        if let path = note.audioPath, !path.isEmpty {
            return true
        }
        return false
    }
}

#Preview {
    NoteCardView(note: Note.mock, namespace: Namespace().wrappedValue, viewModel: NotesViewModel())
}
