//
//  OnboardingScreenModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 08/11/2025.
//

import SwiftUI

struct OnboardingStep {
    let name: String
    let description: String
    let image: Image
    var drawOn: Bool = false
}

extension OnboardingStep {
    static func stepsSetup() -> [OnboardingStep] {
        let first = OnboardingStep(name: Texts.OnboardingPage.FirstPage.title,
                                   description: Texts.OnboardingPage.FirstPage.description,
                                   image: .OnboardingPage.first)
        
        let second = OnboardingStep(name: Texts.OnboardingPage.SecondPage.title,
                                    description: Texts.OnboardingPage.SecondPage.description,
                                    image: .OnboardingPage.second)
        
        let third = OnboardingStep(name: Texts.OnboardingPage.ThirdPage.title,
                                   description: Texts.OnboardingPage.ThirdPage.description,
                                   image: .OnboardingPage.third)
        
        let fourth = OnboardingStep(name: Texts.OnboardingPage.FourthPage.title,
                                    description: Texts.OnboardingPage.FourthPage.description,
                                    image: .OnboardingPage.fourth)
        
        return [first, second, third, fourth]
    }
}


enum OnboardingButtonType {
    case nextPage
    case getMicrophonePermission
    case getLocationPermission
    
    internal var title: String {
        switch self {
        case .nextPage:
            Texts.OnboardingPage.next
        case .getMicrophonePermission, .getLocationPermission:
            Texts.OnboardingPage.permission
        }
    }
}
