//
//  AudioDescriptionView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 31.10.2025.
//

import SwiftUI
import AVFoundation

struct SingleAudioDescriptionView: View {
    
    private let note: Note
    @State private var isEditing = false
    @State private var audioDuration: TimeInterval? = nil
    
    init(note: Note) {
        self.note = note
        self._audioDuration = State(initialValue: Self.getAudioDuration(for: note))
    }
    
    internal var body: some View {
        VStack(alignment: .leading) {
            headTitle
            
            HStack {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .background(.white)
                        .clipShape(Capsule())
                        .foregroundStyle(Color.SupportColors.blue)
                    
                    Text(formatDuration(audioDuration))
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
        .navigationTitle(note.location?.cityName ?? "City")
        .navigationSubtitle(note.location?.streetName ?? "Street")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup {
//                Button(action: {
//                    isEditing.toggle()
//                }) {
//                    Image(systemName: "pencil.line")
//                        .foregroundStyle(Color.SupportColors.blue)
//                }
                
                if let url = URL(string: "https://itmo.ru") {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.SupportColors.blue)
                    }
                }
            }
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
    
    private static func getAudioDuration(for note: Note) -> TimeInterval? {
        guard let path = note.audioPath else { return nil }
        let url = URL(fileURLWithPath: path)
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player.duration
        } catch {
            print("Ошибка при получении длительности аудиофайла: \(error)")
            return nil
        }
    }
    
    private func formatDuration(_ interval: TimeInterval?) -> String {
        guard let interval = interval else { return "--:--" }
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
        location: Location(latitude: 0, longitude: 0, cityName: "Sample City", streetName: "Sample Street")
    )
    NavigationStack {
        SingleAudioDescriptionView(note: mock)
    }
}
