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
    @StateObject private var detailsVM: RecordDetailsViewModel

    @State private var isEditing = false
    @State private var audioDuration: TimeInterval? = nil
    @State private var audioPath: String?
    @State private var displayedTranscription: String
    @State private var displayedUpdatedAt: Date
    @State private var isShowingServerShare = false
    
    private let note: Note
    private let namespace: Namespace.ID
    
    init(note: Note, namespace: Namespace.ID, viewModel: NotesViewModel) {
        self.note = note
        self.namespace = namespace
        self.viewModel = viewModel
        
        let vm = NoteShareViewModel(note: note)
        _shareVM = StateObject(wrappedValue: vm)
        _detailsVM = StateObject(wrappedValue: RecordDetailsViewModel(recordId: Int64(note.serverId ?? "")))
        self._audioDuration = State(initialValue: vm.getAudioDuration(for: note))
        self._audioPath = State(initialValue: note.audioPath)
        self._displayedTranscription = State(initialValue: note.transcription ?? Texts.NotesPage.inProgress)
        self._displayedUpdatedAt = State(initialValue: note.updatedAt)
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
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if detailsVM.canLoadRemoteDetails {
                        processingSection
                        summarySection
                    }
                    transcriptionSection
                }
                .padding(.bottom)
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
        .sheet(isPresented: $isShowingServerShare) {
            ServerShareSheetView(detailsVM: detailsVM, isPresented: $isShowingServerShare)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
            displayedUpdatedAt = updatedNote.updatedAt
            if let updatedAudioPath = updatedNote.audioPath, !updatedAudioPath.isEmpty {
                audioPath = updatedAudioPath
            }

            var durationNote = updatedNote
            if durationNote.audioPath?.isEmpty ?? true {
                durationNote.audioPath = audioPath
            }
            audioDuration = shareVM.getAudioDuration(for: durationNote)
        }
        .task {
            await viewModel.fetchPlaceNamesIfNeeded(for: note)
            detailsVM.load()
        }
        .onDisappear {
            detailsVM.stopPolling()
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
            playButtonIcon
            
            Text(shareVM.formatDuration(audioDuration))
                .font(.subheadline)
                .padding(.trailing, 16)
                .foregroundStyle(Color.LabelColors.white)
        }
        .matchedTransitionSource(id: note.id, in: namespace)
        .glassEffect(.regular.interactive().tint(Color.SupportColors.lightBlue))
        .onTapGesture {
            playButtonAction()
        }
        .disabled(shareVM.isLoading)
        .symbolEffect(.breathe, isActive: shareVM.isLoading)
    }

    @ViewBuilder
    private var playButtonIcon: some View {
        if shareVM.isLoading {
            ProgressView()
                .controlSize(.small)
                .frame(width: 32, height: 32)
                .background(.white)
                .clipShape(Capsule())
        } else if isValidAudioPath {
            Image.NotesPage.play
                .resizable()
                .frame(width: 32, height: 32)
                .background(.white)
                .clipShape(Capsule())
                .foregroundStyle(Color.SupportColors.blue)
        } else {
            Image.NotesPage.download
                .resizable()
                .frame(width: 32, height: 32)
                .background(.white)
                .clipShape(Capsule())
                .foregroundStyle(Color.SupportColors.blue)
        }
    }

    private func playButtonAction() {
        guard !shareVM.isLoading else { return }

        if isValidAudioPath {
            viewModel.selectedNote = playableNote
        } else {
            downloadAudioForPlayback()
        }
    }

    private func downloadAudioForPlayback() {
        Task {
            do {
                let fileURL = try await shareVM.downloadAudioForPlayback()
                await MainActor.run {
                    audioPath = fileURL.path
                    var updatedNote = note
                    updatedNote.audioPath = fileURL.path
                    audioDuration = shareVM.getAudioDuration(for: updatedNote)
                    Toast.shared.present(title: "\(Texts.NotesPage.loadSuccessFirst) \"\(note.title)\" \(Texts.NotesPage.loadSuccessSecond)")
                }
            } catch {
                await MainActor.run {
                    shareVM.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var isValidAudioPath: Bool {
        if let audioPath, !audioPath.isEmpty {
            return true
        }
        return false
    }

    private var playableNote: Note {
        guard let audioPath, !audioPath.isEmpty else {
            return note
        }

        var updatedNote = note
        updatedNote.audioPath = audioPath
        if let audioDuration {
            updatedNote.duration = Int(audioDuration)
        }
        return updatedNote
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

    private var processingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.SupportColors.blue)
                Text(Texts.NotesPage.Summary.processingTitle)
                    .font(.headline)
                Spacer()
                if detailsVM.isLoadingDetails {
                    ProgressView()
                }
            }

            statusRow(title: Texts.NotesPage.Summary.transcription, status: detailsVM.transcriptionStatus)
            statusRow(title: Texts.NotesPage.Summary.summarization, status: detailsVM.summarizationStatus)
        }
        .padding(.vertical, 8)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Texts.NotesPage.Summary.title)
                    .font(.headline)
                Spacer()
                if detailsVM.shouldPollSummary {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let failed = detailsVM.summarizationStatus, failed.status == .failed {
                Text(failed.errorMessage ?? Texts.NotesPage.Summary.failed)
                    .font(.body())
                    .foregroundStyle(Color.SupportColors.red)
                    .id("summary-error-\(failed.errorMessage ?? Texts.NotesPage.Summary.failed)")
                    .transition(.blurReplace)
            } else if let summary = detailsVM.summary?.summaryText, !summary.isEmpty {
                Text(cleanMarkdown(summary))
                    .font(.body())
                    .foregroundStyle(Color.LabelColors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id("summary-\(summary)")
                    .transition(.blurReplace)
            } else {
                Text(Texts.NotesPage.Summary.waiting)
                    .font(.body())
                    .foregroundStyle(Color.LabelColors.secondary)
                    .id("summary-waiting")
                    .transition(.blurReplace)
            }
        }
        .padding(16)
        .background(Color.SupportColors.lightBlue.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.smooth(duration: 0.35), value: detailsVM.summary?.summaryText)
        .animation(.smooth(duration: 0.35), value: detailsVM.summarizationStatus)
    }

    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Texts.NotesPage.Summary.fullTranscription)
                .font(.headline)

            Text(resolvedTranscription)
                .font(.body())
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(resolvedTranscription)
                .transition(.blurReplace)
        }
        .animation(.smooth(duration: 0.35), value: resolvedTranscription)
    }

    private var shareMenu: some View {
        Menu {
            sharePDFButton
            shareAudioButton
            if viewModel.accessRole(for: note) == .owner, detailsVM.canLoadRemoteDetails {
                Button {
                    isShowingServerShare = true
                } label: {
                    Label(Texts.NotesPage.Sharing.openAccess, systemImage: "person.crop.circle.badge.plus")
                }
            }
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
        let localTranscription = displayedTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        let remoteTranscription = detailsVM.record?.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmed: String

        if shouldPreferLocalTranscription, !localTranscription.isEmpty, localTranscription != Texts.NotesPage.inProgress {
            trimmed = localTranscription
        } else if !remoteTranscription.isEmpty {
            trimmed = remoteTranscription
        } else {
            trimmed = localTranscription
        }

        return trimmed.isEmpty ? Texts.NotesPage.inProgress : trimmed
    }

    private var shouldPreferLocalTranscription: Bool {
        guard let record = detailsVM.record else {
            return true
        }

        guard let remoteUpdatedAt = record.updatedAt ?? record.datetime ?? record.createdAt else {
            return false
        }

        return displayedUpdatedAt > remoteUpdatedAt
    }

    private func statusRow(title: String, status: ProcessingStatusResponse?) -> some View {
        HStack(spacing: 10) {
            statusIcon(for: status?.status)
            Text(title)
                .font(.body())
            Spacer()
            Text(statusTitle(for: status?.status))
                .font(.caption(.semibold))
                .foregroundStyle(Color.LabelColors.secondary)
        }
    }

    private func statusIcon(for status: ProcessingStatus?) -> some View {
        Group {
            switch status {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.SupportColors.blue)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.SupportColors.red)
            case .pending, .inProgress:
                ProgressView()
                    .controlSize(.small)
            case .none:
                Image(systemName: "clock")
                    .foregroundStyle(Color.LabelColors.secondary)
            }
        }
        .frame(width: 22, height: 22)
    }

    private func statusTitle(for status: ProcessingStatus?) -> String {
        switch status {
        case .pending:
            return Texts.NotesPage.Summary.pending
        case .inProgress:
            return Texts.NotesPage.Summary.inProgress
        case .completed:
            return Texts.NotesPage.Summary.completed
        case .failed:
            return Texts.NotesPage.Summary.failed
        case .none:
            return Texts.NotesPage.Summary.unknown
        }
    }

    private func cleanMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
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
