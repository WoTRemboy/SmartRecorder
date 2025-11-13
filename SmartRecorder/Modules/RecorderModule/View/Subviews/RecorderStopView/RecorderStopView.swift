//
//  RecorderStopView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 02.11.2025.
//

import SwiftUI

struct RecorderStopView: View {
    
    @EnvironmentObject private var viewModel: RecorderViewModel
    @EnvironmentObject private var appRouter: AppRouter
    
    private let namespace: Namespace.ID
    
    init(namespace: Namespace.ID) {
        self.namespace = namespace
    }
    
    internal var body: some View {
        VStack(spacing: 84) {
            aqualizerView
            controlView
        }
        .transition(.blurReplace)
    }
    
    private var aqualizerView: some View {
        Image.RecorderPage.wave
            .resizable()
            .scaledToFit()
            .foregroundColor(Color.LabelColors.blue)
            .font(Font.buttonTitle())
            .padding(.horizontal, 70)
    }
    
    private var controlView: some View {
        GlassEffectContainer {
            HStack {
                if viewModel.showTimerView {
                    timerView
                }
                stopRecordingButton
            }
        }
        .frame(height: 70)
        .padding(.horizontal)
    }
    
    private var stopRecordingButton: some View {
        Button {
            withAnimation(.bouncy(duration: 0.3)) {
                viewModel.toggleRecording()
            }
        } label: {
            Image.RecorderPage.stopRecording
                .foregroundColor(Color.LabelColors.white)
                .font(Font.buttonTitle2())
                .frame(width: 60, height: 70)
        }
        .matchedGeometryEffect(id: Texts.GeometryEffectId.Recorder.control, in: namespace)
        .glassEffectID(Texts.GlassEffectId.Recorder.stop, in: namespace)
        
        .buttonStyle(.glassProminent)
        .tint(Color.SupportColors.red)
    }
    
    private var timerView: some View {
        Text(viewModel.timerString)
            .font(.largeTitle(.semibold))
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        
            .glassEffect(.regular.interactive())
            .glassEffectID(Texts.GlassEffectId.Recorder.timer, in: namespace)
        
            .contentTransition(.numericText(value: viewModel.elapsedTime))
            .animation(.default, value: viewModel.elapsedTime)
    }
}

#Preview {
    RecorderStopView(namespace: Namespace().wrappedValue)
        .environmentObject(RecorderViewModel())
        .environmentObject(AppRouter())
}
