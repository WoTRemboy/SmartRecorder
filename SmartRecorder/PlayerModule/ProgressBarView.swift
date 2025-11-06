//
//  ProgressBarView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 22.10.2025.
//

import SwiftUI
import AVKit
internal import Combine

struct ProgressBarView: View {
    
    // тестовое аудио не залито в репозиторий 
    let fileName = "testAudio1"
    
    @State private var player: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0.0
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
                Text(String("\(timeIntervalToString(currentTime))"))
                Spacer()
                Text(String("\(timeIntervalToString(player?.duration ?? 0.0))"))
            }
            .font(Font.caption(.semibold))
            .foregroundColor(.SupportColors.blue.opacity(0.75))
            
            HStack(spacing: 20) {
                Button {
                    player?.currentTime -= 10.0
                }
                label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20, weight: .regular))
                        .padding(20)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                
                // нужно исправить поведение кнопки по окончании аудио
                Button {
                    isPlaying ? pauseAudio() : playAudio()
                }
                label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 40, weight: .regular))
                        .padding(30)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                
                Button {
                    player?.currentTime += 10.0
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
        .onAppear(perform: setUpPlayer)
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateTime()
            calcSliderProgress()
        }
    }
    
    private func calcSliderProgress() {
        sliderProgress = totalWidth / CGFloat(player?.duration ?? 1) * CGFloat(currentTime)
    }
    
    private func setUpPlayer()  {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "flac") else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            currentTime = player.currentTime
            self.player = player
        } catch {
            print("Error initializing player: \(error)")
        }
    }
    
    private func playAudio() {
        player?.play()
        isPlaying = true
    }
    
    private func pauseAudio() {
        player?.pause()
        isPlaying = false
    }
    
    private func updateTime() {
        currentTime = player?.currentTime ?? 0.0
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
