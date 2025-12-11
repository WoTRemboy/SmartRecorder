//
//  ImageExtention.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 23.10.2025.
//

import SwiftUI

extension Image {
    enum Onboarding {
        static let logo = Image("SplashScreenLogo")
    }
    
    enum Tabbar {
        enum Notes {
            static let unselected = Image("NotesTabUnselected")
            static let selected = Image("NotesTabSelected")
            static let system = Image(systemName: "list.bullet.rectangle")
        }
        enum Recorder {
            static let unselected = Image("RecorderTabUnselected")
            static let selected = Image("RecorderTabSelected")
            static let system = Image(systemName: "play.circle")
        }
        enum Profile {
            static let unselected = Image("ProfileTabUnselected")
            static let selected = Image("ProfileTabSelected")
            static let system = Image(systemName: "person")
        }
        enum Search {
            static let system = Image(systemName: "magnifyingglass")
        }
    }
    
    enum OnboardingPage {
        static let first = Image(systemName: "wave.3.right")
        static let second = Image(systemName: "list.bullet")
        static let third = Image(systemName: "microphone.circle")
        static let fourth = Image(systemName: "location.circle")
        static let fifth = Image(systemName: "checkmark")
    }
    
    enum NavigationBar {
        static let chevronDown = Image(systemName: "chevron.down")
        static let location = Image(systemName: "location.fill")
        static let squareAndArrowUp =  Image(systemName: "square.and.arrow.up")
        
    }
    
    enum NotesPage {
        static let share = Image(systemName: "square.and.arrow.up")
        static let play = Image(systemName: "play.circle.fill")
        static let download = Image(systemName: "arrow.down.circle.fill")
        static let empty = Image(systemName: "tray")
        static let pdf = Image(systemName: "doc.richtext")
        static let audio = Image(systemName: "waveform")
    }
    
    enum RecorderPage {
        static let date = Image(systemName: "calendar")
        static let location = Image(systemName: "location.fill")
        static let stopRecording = Image(systemName: "stop.fill")
        static let wave = Image(systemName: "waveform")
        static let check = Image(systemName: "checkmark")
    }
}
