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
    @State private var enhancementGradientRotation: Double = 0
    
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
        GlassEffectContainer {
            HStack {
                enhanceButton
                if isEnhancing {
                    stopEnhancementButton
                }
            }
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
        .task {
            enhancementGradientRotation = 0
            withAnimation(.linear(duration: 15.0).repeatForever(autoreverses: false)) {
                enhancementGradientRotation = 360
            }
        }
    }

    @ViewBuilder
    private var enhanceButton: some View {
        if isEnhancing {
            enhancementProgressPill
        } else {
            HStack(spacing: 14) {
                enhancementIcon
                
                Text(enhancementButtonTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                viewModel.startEnhancement(for: note)
            }
            .glassEffect(.regular.interactive())
            .overlay {
                enhancementGradientOverlay
            }
        }
    }

    private var enhancementProgressPill: some View {
        HStack(spacing: 14) {
            enhancementIcon

            Text(Texts.NotesPage.Enhancement.processing)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive())
        .overlay {
            enhancementGradientOverlay
        }
    }

    private var stopEnhancementButton: some View {
            Image(systemName: "stop.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 70, height: 70)
            .onTapGesture {
                viewModel.cancelEnhancement(for: note.id)
            }
            .glassEffect(.regular.tint(.red).interactive())
    }

    private var enhancementGradientOverlay: some View {
        GeometryReader { proxy in
            let side = max(proxy.size.width, 0)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    AngularGradient(
                        colors: [
                            Color(red: 0.23, green: 0.86, blue: 1.00).opacity(0.00),
                            Color(red: 0.23, green: 0.86, blue: 1.00).opacity(0.44),
                            Color(red: 0.52, green: 0.42, blue: 1.00).opacity(0.5),
                            Color(red: 1.00, green: 0.38, blue: 0.82).opacity(0.52),
                            Color(red: 1.00, green: 0.78, blue: 0.36).opacity(0.4),
                            Color(red: 0.23, green: 0.86, blue: 1.00).opacity(0.00)
                        ],
                        center: .center
                    )
                )
                .frame(width: side, height: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .blur(radius: 10)
                .scaleEffect(1.18)
                .rotationEffect(.degrees(enhancementGradientRotation))
                .blendMode(.screen)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .mask {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                }
                .allowsHitTesting(false)
        }
    }

    private var enhancementIcon: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(isEnhancing ? 0.18 : 0.12))
                .frame(width: 40, height: 40)

            Image(systemName: wasRecentlyEnhanced ? "checkmark.circle.fill" : "wand.and.stars")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .phaseAnimator(iconPhases) { content, phase in
                    content
                        .scaleEffect(phase.iconScale)
                        .opacity(phase.iconOpacity)
                } animation: { phase in
                    phase.iconAnimation
                }
        }
        .contentTransition(.opacity)
    }

    private var enhancementButtonTitle: String {
        wasRecentlyEnhanced ? Texts.NotesPage.Enhancement.successShort : Texts.NotesPage.Enhancement.action
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

    private var iconPhases: [EnhancementPhase] {
        if wasRecentlyEnhanced {
            return [.rest]
        }

        return isEnhancing ? EnhancementPhase.allCases : [.rest]
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

private enum EnhancementPhase: CaseIterable {
    case rest
    case lifted
    case settled

    var scale: CGFloat {
        switch self {
        case .rest:
            return 1.0
        case .lifted:
            return 1.02
        case .settled:
            return 0.995
        }
    }

    var highlightOpacity: Double {
        switch self {
        case .rest:
            return 0.08
        case .lifted:
            return 0.22
        case .settled:
            return 0.12
        }
    }

    var iconScale: CGFloat {
        switch self {
        case .rest:
            return 1.0
        case .lifted:
            return 1.18
        case .settled:
            return 0.98
        }
    }

    var iconOpacity: Double {
        switch self {
        case .rest:
            return 0.95
        case .lifted:
            return 1.0
        case .settled:
            return 0.88
        }
    }

    var animation: Animation? {
        switch self {
        case .rest:
            return .smooth(duration: 0.2)
        case .lifted:
            return .easeInOut(duration: 0.55)
        case .settled:
            return .spring(duration: 0.45, bounce: 0.35)
        }
    }

    var iconAnimation: Animation? {
        switch self {
        case .rest:
            return .smooth(duration: 0.2)
        case .lifted:
            return .easeInOut(duration: 0.6)
        case .settled:
            return .spring(duration: 0.45, bounce: 0.4)
        }
    }
}

#Preview {
    NavigationStack {
        SingleAudioDescriptionView(note: Note.mock, namespace: Namespace().wrappedValue, viewModel: NotesViewModel())
    }
}
