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
        VStack(spacing: 36) {
            aqualizerView
            liveTranscriptionView
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

    private var liveTranscriptionView: some View {
        LiveTranscriptionView(
            text: viewModel.liveTranscription,
            isTranscribing: viewModel.isTranscribing
        )
        .padding(.horizontal, 20)
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

private struct LiveTranscriptionView: View {
    let text: String
    let isTranscribing: Bool

    private var visibleLines: [String] {
        let cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedText.isEmpty else { return [] }

        let chunks = cleanedText.chunkedTranscriptLines()
        return Array(chunks.suffix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Circle()
                    .fill(isTranscribing ? Color.SupportColors.blue : Color.LabelColors.secondary.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .scaleEffect(isTranscribing ? 1.0 : 0.72)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isTranscribing)

                Text(Texts.RecorderPage.liveTranscriptTitle)
                    .font(Font.subheadline())
                    .foregroundStyle(Color.LabelColors.secondary)

                Spacer()
            }

            if visibleLines.isEmpty {
                Text(
                    isTranscribing
                    ? Texts.RecorderPage.liveTranscriptProcessing
                    : Texts.RecorderPage.liveTranscriptPlaceholder
                )
                .font(Font.title2(.medium))
                .foregroundStyle(Color.LabelColors.secondary.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 18)
                .transition(.opacity.combined(with: .blurReplace))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(visibleLines.enumerated()), id: \.offset) { index, line in
                        transcriptLine(line, isNewestLine: index == visibleLines.count - 1)
                    }
                }
                .contentTransition(.interpolate)
                .animation(.snappy(duration: 0.45, extraBounce: 0.08), value: visibleLines)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.BackgroundColors.card.opacity(0.92),
                            Color.BackgroundColors.primary.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    private func transcriptLine(_ line: String, isNewestLine: Bool) -> some View {
        let foregroundColor = isNewestLine
            ? Color.LabelColors.primary
            : Color.LabelColors.secondary.opacity(0.72)
        let insertionTransition = AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.96, anchor: .bottom))

        Text(line)
            .font(isNewestLine ? Font.title2(.semibold) : Font.body())
            .foregroundStyle(foregroundColor)
            .blur(radius: isNewestLine ? 0 : 0.6)
            .offset(y: isNewestLine ? 0 : -2)
            .transition(.asymmetric(insertion: insertionTransition, removal: .opacity))
    }
}

private extension String {
    func chunkedTranscriptLines(maxWordsPerLine: Int = 7) -> [String] {
        let words = split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }

        var lines: [String] = []
        var currentLine: [String] = []

        for word in words {
            currentLine.append(word)
            let endsPhrase = word.last.map { ".!?,".contains($0) } ?? false

            if currentLine.count >= maxWordsPerLine || endsPhrase {
                lines.append(currentLine.joined(separator: " "))
                currentLine.removeAll(keepingCapacity: true)
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine.joined(separator: " "))
        }

        return lines
    }
}
