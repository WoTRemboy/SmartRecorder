//
//  NoteCardView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI

struct AudioCardView: View {
    
    @State private var isEditing = false
    @ObservedObject var audio: Audio
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                
                Text(audio.headline)
                    .font(.headline)
            
                Spacer()
                
                if let url = URL(string: "https://itmo.ru") {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color.SupportColors.blue)
                    }
                }
            }
            
            Text(audio.subheadline)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color.LabelColors.secondary)
                .padding(.bottom, 16)
            
            HStack(alignment: .bottom) {
                ChipsView(text: audio.date)

                ChipsView(text: audio.time)

                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(Color.SupportColors.blue)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .background(Color(.white))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
