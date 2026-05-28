//
//  RecorderStartView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 02.11.2025.
//

import SwiftUI
import OSLog
import AVFAudio

/// A logger instance for debug and error messages.
private let logger = Logger(subsystem: "com.transono.recorder", category: "StartRecView")

struct RecorderStartView: View {
    
    @EnvironmentObject private var viewModel: RecorderViewModel
    @EnvironmentObject private var appRouter: AppRouter
    
    private let namespace: Namespace.ID
    
    init(namespace: Namespace.ID) {
        self.namespace = namespace
    }
    
    internal var body: some View {
        VStack(spacing: 84) {
            VStack {
                recorderButton
                HStack {
                    Spacer()
                    microphoneChoiceMenu
                        .padding(.trailing, 50)
                    }
            }
            descriptionLabel
        }
        .transition(.blurReplace)
    }

    private var microphoneChoiceMenu: some View {
        Menu {
            ForEach(viewModel.availableMicrophones, id: \.self) { device in
                        Button {
                            viewModel.changeMicrophone(device)
                        } label: {
                            HStack {
                                Text(device.portName)
                                Spacer()
                                if viewModel.microphone != nil && viewModel.microphone!.uid == device.uid {
                                    Image.RecorderPage.check
                                }
                            }
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.SupportColors.lightBlue)
                            .frame(width: 55, height: 55)
                        
                        Image.RecorderPage.chooseMicrophone .font(Font.title2)
                            .foregroundColor(Color.LabelColors.white)
                    }
                }.compositingGroup()
            }
    
    private var recorderButton: some View {
        Button {
            withAnimation(.bouncy(duration: 0.3)) {
                viewModel.toggleRecording()
            }
        } label: {
            Circle()
                .foregroundStyle(Color.clear)
                .overlay {
                    Text(Texts.Button.recorder)
                        .foregroundColor(Color.LabelColors.white)
                        .font(Font.buttonTitle())
                }
        }
        .matchedGeometryEffect(id: Texts.GeometryEffectId.Recorder.control, in: namespace)
        .buttonStyle(.glassProminent)
        .tint(Color.SupportColors.blue)
        .padding(.horizontal, 60)
    }
    
    private var descriptionLabel: some View {
        markdownContent
            .multilineTextAlignment(.center)
            .font(Font.title2(.medium))
            .foregroundStyle(Color.LabelColors.secondary)
            .padding(.horizontal, 40)
            .onTapGesture {
                appRouter.setTab(to: .notes)
            }
    }
    
    private var markdownContent: some View {
        if var attributedText = try? AttributedString(markdown: Texts.RecorderPage.message) {
            if let range = attributedText.range(of: Texts.RecorderPage.range) {
                attributedText[range].foregroundColor = Color.LabelColors.blue
            }
            return Text(attributedText)
            
        } else {
            logger.error("Attributed terms string creation failed from markdown.")
            return Text(Texts.RecorderPage.message)
                
        }
    }
}

#Preview {
    RecorderStartView(namespace: Namespace().wrappedValue)
        .environmentObject(RecorderViewModel())
        .environmentObject(AppRouter())
}
