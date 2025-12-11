//
//  RecorderStopView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 02.11.2025.
//

import SwiftUI

struct RecorderStopView: View {
    
    @EnvironmentObject private var viewModel: RecorderViewModel
    
    internal var body: some View {
        VStack {
            Button {
                
            } label: {
                Image(systemName: "waveform")
                    .frame(width: 275, height: 275)
                    .foregroundColor(.white)
                    .font(Font.buttonTitle())
                    .background(.green)
                    .clipShape(Circle())
            }
            .padding(.vertical, 85)
            
        }
    }
    
    private var stopRecordingButton: some View {
        Button {
            viewModel.toggleRecording()
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

#Preview {
    RecorderStopView()
        .environmentObject(RecorderViewModel())
}
