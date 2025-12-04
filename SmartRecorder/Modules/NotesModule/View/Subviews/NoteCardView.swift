//
//  NoteCardView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI

struct NoteCardView: View {
    
    @StateObject private var viewModel: NoteShareViewModel
    
    @State private var isEditing = false
    private let note: Note
    
    init(note: Note) {
        self.note = note
        _viewModel = StateObject(wrappedValue: NoteShareViewModel(note: note))
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
        .sheet(isPresented: $viewModel.isPresentingShare, onDismiss: { viewModel.shareURL = nil }) {
            if let url = viewModel.shareURL {
                ActivityView(activityItems: [url])
                    .ignoresSafeArea()
            }
        }
        .alert(Texts.NotesPage.error,
               isPresented: .constant(viewModel.errorMessage != nil),
               actions: {
            Button(Texts.NotesPage.ok) {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ProgressView().progressViewStyle(.circular)
            }
        }
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
        Image.NotesPage.play
            .resizable()
            .frame(width: 64, height: 64)
            .foregroundStyle(Color.SupportColors.blue)
            .glassEffect(.regular.interactive())
            .onTapGesture {
                // Play Button Action
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
            viewModel.sharePDF()
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
            viewModel.shareAudio()
        } label: {
            Label {
                Text(Texts.NotesPage.audio)
            } icon: {
                Image.NotesPage.audio
            }
        }
    }
}

#Preview {
    NoteCardView(note: Note(
        id: UUID(),
        serverId: nil,
        folderId: nil,
        title: "Sample Note",
        transcription: nil,
        audioPath: nil,
        createdAt: .now,
        updatedAt: .now,
        duration: 20,
        location: nil
    ))
}
