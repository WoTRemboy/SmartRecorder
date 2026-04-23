//
//  LiveTranscriptionView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 04/23/2025.
//

import SwiftUI

struct LiveTranscriptionView: View {
    @EnvironmentObject private var viewModel: RecorderViewModel

    let text: String
    let isTranscribing: Bool
    let isExpanded: Bool
    let namespace: Namespace.ID

    @State private var hasAnimatedExpandedContent = false

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
            headerView

            if visibleLines.isEmpty {
                placeholderView
            } else if isExpanded {
                expandedTextView
            } else {
                compactTextView
            }
        }
        .padding(.horizontal, isExpanded ? 24 : 20)
        .padding(.vertical, isExpanded ? 30 : 20)
        .frame(
            maxWidth: .infinity,
            minHeight: isExpanded ? nil : 190,
            maxHeight: isExpanded ? .infinity : nil,
            alignment: .topLeading
        )
        .glassEffect(
            isExpanded
            ? .regular.tint(Color.BackgroundColors.card.opacity(0.32))
            : .regular.interactive().tint(Color.BackgroundColors.card.opacity(0.24)),
            in: RoundedRectangle(cornerRadius: isExpanded ? 36 : 28, style: .continuous)
        )
        .glassEffectID(Texts.GlassEffectId.Recorder.liveTranscript, in: namespace)
        .glassEffectTransition(.matchedGeometry)
        .matchedGeometryEffect(
            id: Texts.GeometryEffectId.Recorder.liveTranscript,
            in: namespace,
            properties: .position,
            isSource: !isExpanded
        )
        .onAppear {
            updateExpandedAnimationState()
        }
        .onChange(of: isExpanded) { _, _ in
            updateExpandedAnimationState()
        }
    }

    private var headerView: some View {
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

            if isExpanded {
                collapseButton
            } else {
                expandHint
            }
        }
        .opacity(isExpanded && !hasAnimatedExpandedContent ? 0.7 : 1)
        .offset(y: isExpanded && !hasAnimatedExpandedContent ? 6 : 0)
        .animation(.easeOut(duration: 0.12), value: hasAnimatedExpandedContent)
    }

    private var expandHint: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(Font.caption(.semibold))
            .foregroundStyle(Color.LabelColors.secondary.opacity(0.9))
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.05))
            )
    }

    private var collapseButton: some View {
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
                viewModel.setLiveTranscriptionExpanded(false)
            }
        } label: {
            Image(systemName: "xmark")
                .font(Font.caption(.semibold))
                .foregroundStyle(Color.LabelColors.primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    private var placeholderView: some View {
        Text(
            isTranscribing
            ? Texts.RecorderPage.liveTranscriptProcessing
            : Texts.RecorderPage.liveTranscriptPlaceholder
        )
        .font(Font.title2(.medium))
        .foregroundStyle(Color.LabelColors.secondary.opacity(0.75))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, isExpanded ? 6 : 18)
        .transition(.opacity.combined(with: .blurReplace))
    }

    private var compactTextView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(visibleLines.enumerated()), id: \.offset) { index, line in
                transcriptLine(line, isNewestLine: index == visibleLines.count - 1)
            }
        }
        .contentTransition(.interpolate)
        .animation(.snappy(duration: 0.45, extraBounce: 0.08), value: visibleLines)
    }

    private var expandedTextView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(expandedLines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(index == expandedLines.count - 1 ? Font.title2(.semibold) : Font.title2(.medium))
                            .foregroundStyle(Color.LabelColors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(hasAnimatedExpandedContent ? 1 : 0)
                            .offset(y: hasAnimatedExpandedContent ? 0 : 12)
                            .blur(radius: hasAnimatedExpandedContent ? 0 : 4)
                            .animation(
                                .spring(response: 0.26, dampingFraction: 0.9)
                                .delay(0.04 * Double(min(index, 8))),
                                value: hasAnimatedExpandedContent
                            )
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.bottom, 28)
                .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .scrollBounceBehavior(.basedOnSize)
            .onChange(of: expandedLines.count) { _, newCount in
                guard newCount > 0 else { return }
                withAnimation(.easeOut(duration: 0.18)) {
                    proxy.scrollTo(newCount - 1, anchor: .bottom)
                }
            }
        }
    }

    private var expandedLines: [String] {
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !lines.isEmpty {
            return lines
        }

        return text.chunkedTranscriptLines(maxWordsPerLine: 10)
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

    private func updateExpandedAnimationState() {
        guard isExpanded else {
            hasAnimatedExpandedContent = false
            return
        }

        hasAnimatedExpandedContent = false
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.9)) {
                hasAnimatedExpandedContent = true
            }
        }
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
