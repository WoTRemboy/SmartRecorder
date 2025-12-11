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
        HStack(alignment: .center, spacing: 6) {
            ForEach(Array(viewModel.amplitudes.enumerated()), id: \.offset) { idx, amp in
                Capsule()
                    .frame(width: 10, height: min(max(8, CGFloat(amp) * 800), 200))
                    .foregroundColor(Color.LabelColors.blue)
                    .animation(.easeOut(duration: 0.08), value: amp)
            }
        }
        .frame(height: 200)
        .padding(.horizontal, 36)
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
