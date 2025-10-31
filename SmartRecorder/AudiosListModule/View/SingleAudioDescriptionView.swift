//
//  AudioDescriptionView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 31.10.2025.
//

import SwiftUI

struct SingleAudioDescriptionView: View {
    
    @ObservedObject var audio: Audio
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("#" + audio.category)
                .foregroundStyle(Color.SupportColors.blue)
            
            if isEditing {
                TextField("Заголовок", text: $audio.headline)
                    .font(.title).bold()
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 8)
            } else {
                Text(audio.headline)
                    .font(.title).bold()
            }
                
            
            HStack {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .background(.white)
                        .clipShape(Capsule())
                    Text(audio.duration)
                        .font(.subheadline)
                        .padding(.trailing, 16)
                }
                .foregroundStyle(Color.SupportColors.blue)
                .background(Color(Color.SupportColors.lightBlue))
                .clipShape(Capsule())
                
                Spacer()
                
                ChipsView(text: audio.date)

                ChipsView(text: audio.time)

            }
            .padding(.bottom, 24)
            
            ScrollView {
                Text(audio.subheadline)
            }
        }
        .padding(.horizontal, 20)
        .navigationTitle(audio.location)
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
}
