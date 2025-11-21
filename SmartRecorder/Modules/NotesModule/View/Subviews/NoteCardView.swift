//
//  NoteCardView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI

struct NoteCardView: View {
    
    @State private var isEditing = false
    private let note: Note
    
    init(note: Note) {
        self.note = note
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
    }
    
    private var titleStack: some View {
        HStack {
            Text(note.title)
                .font(.subheadline())
                .foregroundStyle(Color.LabelColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            shareButton
        }
    }
    
    private var descriptionLabel: some View {
        Text(note.transcription ?? "Transcription")
            .lineLimit(2)
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .foregroundStyle(Color.LabelColors.secondary)
            .padding(.bottom, 16)
    }
    
    private var bottomStack: some View {
        GlassEffectContainer {
            HStack(alignment: .bottom) {
                ChipsView(text: "20 npz")
                ChipsView(text: "dsf")
                
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
    
    private var shareButton: some View {
        Button {
            // Share Button Action
        } label: {
            Image.NotesPage.share
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(Color.SupportColors.blue)
        }
    }
}

#Preview {
    NoteCardView(note: Note(
        id: UUID(),
        serverId: nil,
        folderId: nil,
        title: "Sample Note",
        transcription: "This is a sample transcription for preview purposes.",
        audioPath: nil,
        createdAt: .now,
        updatedAt: .now,
        location: nil
    ))
}
