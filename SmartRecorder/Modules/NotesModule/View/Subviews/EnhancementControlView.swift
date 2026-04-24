//
//  EnhancementControlView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 04/24/2025.
//

import SwiftUI

struct EnhancementControlView: View {

    let isEnhancing: Bool
    let wasRecentlyEnhanced: Bool
    let onStart: () -> Void
    let onStop: () -> Void

    @State private var gradientRotation: Double = 0

    var body: some View {
        GlassEffectContainer {
            HStack {
                enhanceButton
                if isEnhancing {
                    stopEnhancementButton
                }
            }
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
        .task {
            gradientRotation = 0
            withAnimation(.linear(duration: 15.0).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }

    @ViewBuilder
    private var enhanceButton: some View {
        if isEnhancing {
            enhancementProgressPill
        } else {
            HStack(spacing: 14) {
                enhancementIcon

                Text(enhancementButtonTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture(perform: onStart)
            .glassEffect(.regular.interactive())
            .overlay {
                enhancementGradientOverlay
            }
        }
    }

    private var enhancementProgressPill: some View {
        HStack(spacing: 14) {
            enhancementIcon

            Text(Texts.NotesPage.Enhancement.processing)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive())
        .overlay {
            enhancementGradientOverlay
        }
    }

    private var stopEnhancementButton: some View {
        Image(systemName: "stop.fill")
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 70, height: 70)
            .onTapGesture(perform: onStop)
            .glassEffect(.regular.tint(.red).interactive())
    }

    private var enhancementGradientOverlay: some View {
        GeometryReader { proxy in
            let side = max(proxy.size.width, 0)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    AngularGradient(
                        colors: [
                            Color(red: 0.23, green: 0.86, blue: 1.00).opacity(0.00),
                            Color(red: 0.23, green: 0.86, blue: 1.00).opacity(0.44),
                            Color(red: 0.52, green: 0.42, blue: 1.00).opacity(0.5),
                            Color(red: 1.00, green: 0.38, blue: 0.82).opacity(0.52),
                            Color(red: 1.00, green: 0.78, blue: 0.36).opacity(0.4),
                            Color(red: 0.23, green: 0.86, blue: 1.00).opacity(0.00)
                        ],
                        center: .center
                    )
                )
                .frame(width: side, height: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .blur(radius: 10)
                .scaleEffect(1.18)
                .rotationEffect(.degrees(gradientRotation))
                .blendMode(.screen)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .mask {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                }
                .allowsHitTesting(false)
        }
    }

    private var enhancementIcon: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(isEnhancing ? 0.18 : 0.12))
                .frame(width: 40, height: 40)

            Image(systemName: wasRecentlyEnhanced ? "checkmark.circle.fill" : "wand.and.stars")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .phaseAnimator(iconPhases) { content, phase in
                    content
                        .scaleEffect(phase.iconScale)
                        .opacity(phase.iconOpacity)
                } animation: { phase in
                    phase.iconAnimation
                }
        }
        .contentTransition(.opacity)
    }

    private var enhancementButtonTitle: String {
        wasRecentlyEnhanced ? Texts.NotesPage.Enhancement.successShort : Texts.NotesPage.Enhancement.action
    }

    private var iconPhases: [EnhancementPhase] {
        if wasRecentlyEnhanced {
            return [.rest]
        }

        return isEnhancing ? EnhancementPhase.allCases : [.rest]
    }
}
