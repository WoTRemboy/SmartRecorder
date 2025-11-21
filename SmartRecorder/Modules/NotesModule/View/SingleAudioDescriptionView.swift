//
//  AudioDescriptionView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 31.10.2025.
//

import SwiftUI

struct SingleAudioDescriptionView: View {
    
    private let audio: Note
    @State private var isEditing = false
    
    init(audio: Note) {
        self.audio = audio
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
                    Text("duration")
                        .font(.subheadline)
                        .padding(.trailing, 16)
                }
                .foregroundStyle(Color.SupportColors.blue)
                .background(Color(Color.SupportColors.lightBlue))
                .clipShape(Capsule())
                
                Spacer()
                
                ChipsView(text: "Date")

                ChipsView(text: "Time")

            }
            .padding(.bottom, 24)
            
            ScrollView {
                Text(audio.transcription ?? "")
            }
        }
        .padding(.horizontal, 20)
        .navigationTitle(audio.location?.cityName ?? "City")
        .navigationSubtitle(audio.location?.streetName ?? "Street")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup {
                Button(action: {
                    isEditing.toggle()
                }) {
                    Image(systemName: "pencil.line")
                        .foregroundStyle(Color.SupportColors.blue)
                }
                
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
            Text("#" + (audio.folderId ?? "FolderId"))
                .foregroundStyle(Color.SupportColors.blue)
            
            Text(audio.title)
                .font(.title).bold()
        }
    }
}

#Preview {
    let mock = Note(
        id: UUID(),
        serverId: nil,
        folderId: "12345",
        title: "Sample Note Title",
        transcription: "This is a sample transcription for preview purposes.",
        audioPath: nil,
        createdAt: .now,
        updatedAt: .now,
        location: Location(latitude: 0, longitude: 0, cityName: "Sample City", streetName: "Sample Street")
    )
    NavigationStack {
        SingleAudioDescriptionView(audio: mock)
    }
}
