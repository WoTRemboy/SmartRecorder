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
}
