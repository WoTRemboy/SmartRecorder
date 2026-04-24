//
//  AudioDescriptionView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 31.10.2025.
//

import SwiftUI
import CoreLocation

struct SingleAudioDescriptionView: View {
    
    @ObservedObject private var viewModel: NotesViewModel
    @StateObject private var shareVM: NoteShareViewModel

    @State private var isEditing = false
    @State private var audioDuration: TimeInterval? = nil
    @State private var displayedTranscription: String
    
    private let note: Note
    private let namespace: Namespace.ID
    
    init(note: Note, namespace: Namespace.ID, viewModel: NotesViewModel) {
        self.note = note
        self.namespace = namespace
        self.viewModel = viewModel
        
        let vm = NoteShareViewModel(note: note)
        _shareVM = StateObject(wrappedValue: vm)
        self._audioDuration = State(initialValue: vm.getAudioDuration(for: note))
        self._displayedTranscription = State(initialValue: note.transcription ?? Texts.NotesPage.inProgress)
    }
    
    internal var body: some View {
        VStack(alignment: .leading) {
            headTitle
            
            HStack {
                playButton
                Spacer()
                
                GlassEffectContainer {
                    HStack {
                        ChipsView(text: DateService.formattedDate(note.createdAt))
                        ChipsView(text: DateService.formattedTime(note.createdAt))
                    }
                }
                
            }
            .padding(.bottom, 24)

            enhancementSection
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(resolvedTranscription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .navigationTitle(note.location?.cityName ?? viewModel.placeCity(for: note) ?? "")
        .navigationSubtitle(note.location?.streetName ?? viewModel.placeStreet(for: note) ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                shareMenu
            }
        }
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
        .animation(.easeInOut(duration: 0.2), value: shareVM.isLoading)
        .alert(
            Texts.NotesPage.Enhancement.ErrorAlert.title,
            isPresented: enhancementErrorBinding,
            actions: {
                Button(Texts.NotesPage.Enhancement.ErrorAlert.ok) {
                    viewModel.dismissEnhancementError()
                }
            },
            message: {
                Text(viewModel.enhancementErrorMessage ?? "")
            }
        )
        .animation(.smooth(duration: 0.35), value: isEnhancing)
        .animation(.smooth(duration: 0.35), value: wasRecentlyEnhanced)
        .onReceive(viewModel.$notes) { notes in
            guard let updatedNote = notes.first(where: { $0.id == note.id }) else { return }
            displayedTranscription = updatedNote.transcription ?? Texts.NotesPage.inProgress
        }
        .task {
            await viewModel.fetchPlaceNamesIfNeeded(for: note)
        }
    }
    
    private var headTitle: some View {
        VStack(alignment: .leading) {
            Text("#" + (NoteFolder(rawValue: note.folderId ?? "")?.title ?? "FolderId"))
                .foregroundStyle(Color.SupportColors.blue)
            
            Text(note.title)
                .font(.title).bold()
        }
    }
    
    private var playButton: some View {
        HStack {
            Image.NotesPage.play
                .resizable()
                .frame(width: 32, height: 32)
                .background(.white)
                .clipShape(Capsule())
                .foregroundStyle(Color.SupportColors.blue)
            
            Text(shareVM.formatDuration(audioDuration))
                .font(.subheadline)
                .padding(.trailing, 16)
                .foregroundStyle(Color.LabelColors.white)
        }
        .matchedTransitionSource(id: note.id, in: namespace)
        .glassEffect(.regular.interactive().tint(Color.SupportColors.lightBlue))
        .onTapGesture {
            viewModel.selectedNote = note
        }
    }

    private var enhancementSection: some View {
        EnhancementControlView(
            isEnhancing: isEnhancing,
            wasRecentlyEnhanced: wasRecentlyEnhanced,
            onStart: {
                viewModel.startEnhancement(for: note)
            },
            onStop: {
                viewModel.cancelEnhancement(for: note.id)
            }
        )
    }

    private var shareMenu: some View {
        Menu {
            sharePDFButton
            shareAudioButton
        } label: {
            Image.NotesPage.share
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

    private var resolvedTranscription: String {
        let trimmed = displayedTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Texts.NotesPage.inProgress : trimmed
    }

    private var isEnhancing: Bool {
        viewModel.isEnhancing(noteID: note.id)
    }

    private var wasRecentlyEnhanced: Bool {
        viewModel.wasRecentlyEnhanced(noteID: note.id)
    }

    private var enhancementErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.enhancementErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.dismissEnhancementError()
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        SingleAudioDescriptionView(note: Note.mock, namespace: Namespace().wrappedValue, viewModel: NotesViewModel())
    }
}
