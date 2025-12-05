//
//  PlayerUIView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 21.10.2025.
//

import SwiftUI

struct PlayerScreenView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: PlayerViewModel
    @StateObject private var shareVM: NoteShareViewModel
    
    private let note: Note
    private let namespace: Namespace.ID
    
    init(note: Note, namespace: Namespace.ID) {
        self.note = note
        self.namespace = namespace
        
        let viewModel = PlayerViewModel(note: note)
        _viewModel = StateObject(wrappedValue: viewModel)
        let shareVM = NoteShareViewModel(note: note)
        _shareVM = StateObject(wrappedValue: shareVM)
    }
    
    internal var body: some View {
        NavigationStack {
            VStack {
                aqualizerView
                AudioDescriptionView(viewModel: viewModel)
                ProgressBarView(viewModel: viewModel)
            }
            .navigationTitle(note.location?.cityName ?? "")
            .navigationSubtitle(note.location?.streetName ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    dismissButton
                }
            }
        }
        .navigationTransition(
            .zoom(sourceID: note.id,
                  in: namespace)
        )
        .background(Color.BackgroundColors.primary
            .ignoresSafeArea(.all))
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
    }
    
    private var aqualizerView: some View {
        HStack(alignment: .center, spacing: 6) {
            ForEach(Array(viewModel.amplitudes.enumerated()), id: \.offset) { _, amp in
                Capsule()
                    .frame(width: 10, height: min(max(8, CGFloat(amp) * 800), 200))
                    .foregroundColor(Color.LabelColors.blue)
                    .animation(.easeOut(duration: 0.08), value: amp)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 36)
    }
    
    private var dismissButton: some View {
        Button {
            dismiss()
        }
        label: {
            Image.NavigationBar.chevronDown
        }
        .foregroundStyle(Color.LabelColors.purple)
    }
    
    private var shareMenu: some View {
        Menu {
            sharePDFButton
            shareAudioButton
        } label: {
            Image.NotesPage.share
        }
        .foregroundStyle(Color.SupportColors.blue)
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
}

#Preview {
    PlayerScreenView(note: Note.mock, namespace: Namespace().wrappedValue)
}
