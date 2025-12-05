//
//  ProgressBarView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 22.10.2025.
//

import SwiftUI
import Combine

struct ProgressBarView: View {
    
    @ObservedObject private var viewModel: PlayerViewModel
    
    @State private var sliderProgress: CGFloat = 0.0
    @State private var totalWidth: CGFloat = 0.0
    @State private var sliderChangeInProgress: Bool = false
    @State private var currentTimeLabel: TimeInterval = 0.0
    
    private let sliderHeight: CGFloat = 20
    
    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
    }
    
    internal var body: some View {
        VStack {
            sliderView
            timeLabels
            controlButtons
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 20)
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            calcSliderProgress()
        }
    }
    
    private var sliderView: some View {
        ZStack(alignment: .center) {
            Capsule()
                .foregroundColor(.SupportColors.lightBlue)
                .frame(width: sliderProgress)
                .position(x: sliderProgress / 2.0, y: sliderHeight / 2.0)
                .animation(.interactiveSpring, value: sliderProgress)
                .zIndex(1)
            
            Circle()
                .foregroundColor(.SupportColors.lightBlue)
                .opacity(0.0)
                .contentShape(Circle())
                .frame(width: 15.0, height: 15.0)
                .gesture(
                    DragGesture(minimumDistance: 7.5, coordinateSpace: .named("slider"))
                        .onChanged { a in
                            onSliderChanged(a.location.x)
                        }
                        .onEnded { a in
                            onSliderChangeEnded(a.location.x)
                        }
                )
                .position(x: sliderProgress, y: sliderHeight / 2.0)
                .zIndex(2)
            GeometryReader { geometry in
                Capsule()
                    .foregroundColor(.SupportColors.lightBlue).opacity(0.29)
                    .onAppear {
                        totalWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        totalWidth = newWidth
                        calcSliderProgress()
                    }
                    
                    .zIndex(0)
            }
        }
        .frame(height: sliderHeight)
        .glassEffect(.regular.interactive())
        .padding(.bottom, 13)
        .coordinateSpace(name: "slider")
    }
    
    private var timeLabels: some View {
        HStack {
            Text(String("\(timeIntervalToString(currentTimeLabel))"))
            Spacer()
            Text(String("\(timeIntervalToString(viewModel.duration))"))
        }
        .font(Font.caption(.semibold))
        .foregroundColor(.SupportColors.blue.opacity(0.75))
    }
    
    private var controlButtons: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                backButton
                playButton
                forwardButton
            }
        }
        .foregroundColor(.SupportColors.blue)
        .padding()
    }
    
    private var backButton: some View {
        Button {
            viewModel.currentTime = max(0, min(viewModel.currentTime - 5.0, viewModel.duration))
        }
        label: {
            Circle()
                .frame(width: 60.0, height: 60.0)
                .foregroundStyle(Color(.clear))
                .overlay {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20, weight: .regular))
                }
        }
        .glassEffect(.regular.interactive())
    }
    
    private var playButton: some View {
        Button {
            viewModel.togglePlayback()
        }
        label: {
            Circle()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color(.clear))
                .overlay {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 40, weight: .regular))
                        .contentTransition(.symbolEffect(.replace))
                }
        }
        .glassEffect(.regular.interactive())
    }
    
    private var forwardButton: some View {
        Button {
            let target = viewModel.currentTime + 5.0
            if target >= viewModel.duration {
                viewModel.currentTime = max(0, viewModel.duration - 0.05)
            } else {
                viewModel.currentTime = target
            }
        }
        label: {
            Circle()
                .frame(width: 60.0, height: 60.0)
                .foregroundStyle(Color(.clear))
                .overlay {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .regular))
                }
        }
        .glassEffect(.regular.interactive())
    }
    
    private func calcSliderProgress() {
        guard !sliderChangeInProgress else { return }
        guard totalWidth > 0, viewModel.duration > 0 else {
            sliderProgress = 0
            currentTimeLabel = 0
            return
        }
        let clampedCurrent = max(0, min(viewModel.currentTime, viewModel.duration))
        let fraction = CGFloat(clampedCurrent / viewModel.duration).clamped(to: 0...1)
        sliderProgress = totalWidth * fraction
        currentTimeLabel = clampedCurrent
    }
    
    private func onSliderChanged(_ value: CGFloat) {
        guard totalWidth > 0, viewModel.duration > 0 else { return }
        sliderProgress = min(totalWidth, max(value, 0.0))
        sliderChangeInProgress = true
        let fraction = (sliderProgress / totalWidth).clamped(to: 0...1)
        currentTimeLabel = TimeInterval(CGFloat(viewModel.duration) * fraction)
    }
    
    private func onSliderChangeEnded(_ value: CGFloat) {
        sliderChangeInProgress = false
        guard totalWidth > 0, viewModel.duration > 0 else {
            return
        }
        let fraction = (sliderProgress / totalWidth).clamped(to: 0...1)
        let newTime = TimeInterval(CGFloat(viewModel.duration) * fraction)
        viewModel.currentTime = max(0, min(newTime, viewModel.duration))
        currentTimeLabel = viewModel.currentTime
    }
}

private func timeIntervalToString(_ interval: TimeInterval) -> String {
    let totalSeconds = Int(interval)
    let totalMinutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    let minutes = totalMinutes % 60
    let hours = totalMinutes / 60
    
    return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    let viewModel = PlayerViewModel(note: Note.mock)
    ProgressBarView(viewModel: viewModel)
        .background(Color.BackgroundColors.primary
            .ignoresSafeArea(.all))
}

