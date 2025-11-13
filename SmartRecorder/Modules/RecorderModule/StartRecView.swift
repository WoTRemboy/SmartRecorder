//
//  StartRecView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 02.11.2025.
//

import SwiftUI

struct StartRecView: View {
    @Binding var isRecording: Bool
    
    var body: some View {
        VStack {
            Button {
                isRecording.toggle()
            } label: {
                Text(Texts.Button.recorder)
                    .frame(width: 275, height: 275)
                    .foregroundColor(.white)
                    .font(Font.buttonTitle())
                    .background(Color.SupportColors.blue)
                    .clipShape(Circle())
            }
            .padding(.vertical, 85)
            
            Text(Texts.Caption.message)
                .multilineTextAlignment(.center)
                .frame(width: 275)
                .font(Font.title2(.medium))
                .foregroundStyle(Color.LabelColors.secondary)
        }
    }
}

#Preview {
    StartRecView(isRecording: .constant(false))
}
