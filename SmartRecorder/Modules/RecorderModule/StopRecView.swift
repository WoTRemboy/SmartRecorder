//
//  StopRecView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 02.11.2025.
//

import SwiftUI

struct StopRecView: View {
    @Binding var isRecording: Bool
    
    var body: some View {
        VStack {
            Button {
                
            } label: {
                Text("эквалайзер")
                    .frame(width: 275, height: 275)
                    .foregroundColor(.white)
                    .font(Font.buttonTitle())
                    .background(.green)
                    .clipShape(Circle())
            }
            .padding(.vertical, 85)
            Button {
                isRecording.toggle()
            } label: {
                Image(systemName: "stop.fill")
                    .frame(width: 70, height: 70)
                    .foregroundColor(.white)
                    .font(Font.buttonTitle2())
                    .background(Color.SupportColors.red)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    StopRecView(isRecording: .constant(true))
}
