//
//  ProgressBarView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 22.10.2025.
//

import SwiftUI
import Combine

struct ProgressBarView: View {
    @State private var viewModel = PlayerViewModel()
    @State private var sliderProgress: CGFloat = 0.0
    @State private var totalWidth: CGFloat = 0.0
    @State private var sliderChangeInProgress: Bool = false
    @State private var currentTimeLabel: TimeInterval = 0.0
    
    private let sliderHeight = 7.0
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                Capsule()
                    .foregroundColor(.SupportColors.lightBlue)
                    .frame(width: sliderProgress)
                    .position(x: sliderProgress / 2.0, y: sliderHeight / 2.0)
                    .animation(.interactiveSpring, value: sliderProgress)
                
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
                GeometryReader { geometry in
                    Capsule().foregroundColor(.SupportColors.lightBlue).opacity(0.29)
                        .onAppear {
                            totalWidth = geometry.size.width
                        }
                }
                
            }
            .frame(height: sliderHeight)
            .padding(.bottom, 13)
            .coordinateSpace(name: "slider")
            
            HStack {
                Text(String("\(timeIntervalToString(currentTimeLabel))"))
                Spacer()
                Text(String("\(timeIntervalToString(viewModel.duration))"))
            }
            .font(Font.caption(.semibold))
            .foregroundColor(.SupportColors.blue.opacity(0.75))
            
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        viewModel.currentTime -= 10.0
                    }
                    label: {
                        ZStack {
                            Circle().frame(width: 60.0, height: 60.0).foregroundStyle(Color(.clear))
                            Image(systemName: "backward.fill")
                                .font(.system(size: 20, weight: .regular))
                        }
                    }
                    .glassEffect(.regular.interactive())
                    
                    Button {
                        viewModel.toggle()
                    }
                    label: {
                        ZStack {
                            Circle().frame(width: 100, height: 100).foregroundStyle(Color(.clear))
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 40, weight: .regular))
                            
                        }
                    }
                    .glassEffect(.regular.interactive())
                    
                    Button {
                        viewModel.currentTime += 10.0
                    }
                    label: {
                        ZStack {
                            Circle().frame(width: 60.0, height: 60.0).foregroundStyle(Color(.clear))
                            Image(systemName: "forward.fill")
                                .font(.system(size: 20, weight: .regular))
                        }
                    }
                    .glassEffect(.regular.interactive())
                }
            }
            .foregroundColor(.SupportColors.blue)
            .padding(.all)
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 20)
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            calcSliderProgress()
        }
    }
    
    private func calcSliderProgress() {
        if !sliderChangeInProgress {
            sliderProgress = totalWidth * (CGFloat(viewModel.currentTime) / CGFloat(viewModel.duration))
            currentTimeLabel = viewModel.currentTime
        }
    }
    
    private func onSliderChanged(_ value: CGFloat) {
        sliderProgress = min(totalWidth, max(value, 0.0))
        sliderChangeInProgress = true
        currentTimeLabel = CGFloat(viewModel.duration) * (sliderProgress / totalWidth)
    }
    
    private func onSliderChangeEnded(_ value: CGFloat) {
        sliderChangeInProgress = false
        viewModel.currentTime = CGFloat(viewModel.duration) * (sliderProgress / totalWidth)
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

#Preview {
    ProgressBarView()
        .background(Color.BackgroundColors.primary
            .ignoresSafeArea(.all))
}
