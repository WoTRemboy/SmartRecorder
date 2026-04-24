//
//  LiveTranscriptionExpansionLayer.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 04/23/2025.
//

import SwiftUI

struct LiveTranscriptionExpansionLayer: View {
    @EnvironmentObject private var viewModel: RecorderViewModel

    let namespace: Namespace.ID

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                backdrop

                if viewModel.isRecording && viewModel.isLiveTranscriptionExpanded {
                    LiveTranscriptionView(
                        text: viewModel.liveTranscription,
                        isTranscribing: viewModel.isTranscribing,
                        isExpanded: true,
                        namespace: namespace
                    )
                    .environmentObject(viewModel)
                    .frame(
                        width: max(0, proxy.size.width - 32),
                        height: max(0, (proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom) * 0.5)
                    )
                    .padding(.top, proxy.safeAreaInsets.top)
                    .padding(.bottom, proxy.safeAreaInsets.bottom)
                    .shadow(color: Color.black.opacity(0.12), radius: 30, y: 14)
                    .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .allowsHitTesting(viewModel.isRecording && viewModel.isLiveTranscriptionExpanded)
    }

    private var backdrop: some View {
        Rectangle()
            .fill(Color.black.opacity(viewModel.isRecording && viewModel.isLiveTranscriptionExpanded ? 0.24 : 0))
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.11), value: viewModel.isLiveTranscriptionExpanded)
            .onTapGesture {
                guard viewModel.isLiveTranscriptionExpanded else { return }
                withAnimation(.spring(response: 0.22, dampingFraction: 0.92)) {
                    viewModel.setLiveTranscriptionExpanded(false)
                }
            }
    }
}
