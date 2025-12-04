//
//  AudioDescriptionView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 31.10.2025.
//

import SwiftUI

struct SingleAudioDescriptionView: View {
    
    @StateObject private var viewModel: NoteShareViewModel

    @State private var isEditing = false
    @State private var audioDuration: TimeInterval? = nil
    
    private let note: Note
    
    init(note: Note) {
        self.note = note
        
        let vm = NoteShareViewModel(note: note)
        _viewModel = StateObject(wrappedValue: vm)
        self._audioDuration = State(initialValue: vm.getAudioDuration(for: note))
    }
    
    internal var body: some View {
        VStack(alignment: .leading) {
            headTitle
            
            HStack {
                HStack {
                    Image.NotesPage.play
                        .resizable()
                        .frame(width: 32, height: 32)
                        .background(.white)
                        .clipShape(Capsule())
                        .foregroundStyle(Color.SupportColors.blue)
                    
                    Text(viewModel.formatDuration(audioDuration))
                        .font(.subheadline)
                        .padding(.trailing, 16)
                        .foregroundStyle(Color.LabelColors.white)
                }
                
                .background(Color(Color.SupportColors.lightBlue))
                .clipShape(Capsule())
                
                Spacer()
                
                GlassEffectContainer {
                    HStack {
                        ChipsView(text: DateService.formattedDate(note.createdAt))
                        ChipsView(text: DateService.formattedTime(note.createdAt))
                    }
                }
                
            }
            .padding(.bottom, 24)
            
            ScrollView {
                Text(note.transcription ?? Texts.NotesPage.inProgress)
            }
        }
        .padding(.horizontal, 20)
        .navigationTitle(note.location?.cityName ?? Texts.NotesPage.city)
        .navigationSubtitle(note.location?.streetName ?? Texts.NotesPage.street)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup {
                shareMenu
            }
        }
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
            if viewModel.isLoading { ProgressView().progressViewStyle(.circular) }
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
    let mock = Note(
        id: UUID(),
        serverId: nil,
        folderId: "note_folder_work",
        title: "Sample Note Title",
        transcription: nil,
        audioPath: nil,
        createdAt: .now,
        updatedAt: .now,
        duration: 20,
        location: Location(latitude: 0, longitude: 0, cityName: "Sample City", streetName: "Sample Street")
    )
    NavigationStack {
        SingleAudioDescriptionView(note: mock)
    }
}

