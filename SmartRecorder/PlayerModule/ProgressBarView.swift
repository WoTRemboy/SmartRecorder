//
//  ProgressBarView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 22.10.2025.
//

import SwiftUI
internal import Combine

struct ProgressBarView: View {
    @State private var viewModel = PlayerViewModel()
    @State private var sliderProgress: CGFloat = 0.0
    @State private var totalWidth: CGFloat = 0.0
    
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                Capsule()
                    .foregroundColor(.SupportColors.lightBlue)
                    .frame(width: sliderProgress)
                
                GeometryReader { geometry in
                    Capsule().foregroundColor(.SupportColors.lightBlue).opacity(0.29)
                        .onAppear {
                            totalWidth = geometry.size.width
                        }
                }
                
            }
            .frame(height: 7)
            .padding(.bottom, 13)
            
            HStack {
                Text(String("\(timeIntervalToString(viewModel.currentTime))"))
                Spacer()
                Text(String("\(timeIntervalToString(viewModel.duration))"))
            }
            .font(Font.caption(.semibold))
            .foregroundColor(.SupportColors.blue.opacity(0.75))
            
            HStack(spacing: 20) {
                Button {
                    viewModel.currentTime -= 10.0
                }
                label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20, weight: .regular))
                        .padding(20)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                
                // нужно исправить поведение кнопки по окончании аудио
                Button {
                    viewModel.toggle()
                }
                label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 40, weight: .regular))
                        .padding(30)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                
                Button {
                    viewModel.currentTime += 10.0
                }
                label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .regular))
                        .padding(20)
                }
                .glassEffect(.regular.interactive(), in: .circle)
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
        sliderProgress = totalWidth / CGFloat(viewModel.duration) * CGFloat(viewModel.currentTime)
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
