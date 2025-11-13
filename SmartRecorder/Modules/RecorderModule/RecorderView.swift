//
//  RecorderView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 29.10.2025.
//

import SwiftUI

struct RecorderView: View {
    
    @State private var isRecording: Bool = false
    
    var body: some View {
        ZStack {
            Color.BackgroundColors.primary
                .ignoresSafeArea(.all)
            VStack {
                VStack(spacing: 5) {
                    Label("16.09.2025", systemImage: "calendar")
                        .font(Font.title2())
                        .foregroundStyle(Color.LabelColors.purple)
                    
                    Label(Texts.NavigationBar.location, systemImage: "location.fill")
                        .font(Font.title2())
                        .foregroundColor(Color.LabelColors.purple)
                }
                
                if isRecording == false {
                    StartRecView(isRecording: $isRecording)
                }
                
                if isRecording {
//                  заглушка вместо эквалайзера
                    
                    StopRecView(isRecording: $isRecording)
                }
            }
       
        }
    }
}

#Preview {
    RecorderView()
}
