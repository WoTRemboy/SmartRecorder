//
//  OnboardingScreenModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 08/11/2025.
//

import SwiftUI
import CoreLocation
import AVFoundation

struct OnboardingStep {
    let name: String
    let description: String
    let image: Image
    var drawOn: Bool = false
    var grantedAccess: Bool = false
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
                                   image: .OnboardingPage.third,
                                   grantedAccess: AVAudioApplication.shared.recordPermission == .granted)
        
        let fourth = OnboardingStep(name: Texts.OnboardingPage.FourthPage.title,
                                    description: Texts.OnboardingPage.FourthPage.description,
                                    image: .OnboardingPage.fourth,
                                    grantedAccess: LocationService.shared.grantedAccess)
        
        return [first, second, third, fourth]
    }
}


enum OnboardingButtonType: Equatable {
    case nextPage
    case getMicrophonePermission(access: AVAudioApplication.recordPermission)
    case getLocationPermission(access: CLAuthorizationStatus)
    
    internal var title: String {
        switch self {
        case .nextPage:
            return Texts.OnboardingPage.next
            
        case .getMicrophonePermission(let access):
            switch access {
            case .undetermined:
                return Texts.OnboardingPage.permission
            case .granted:
                return Texts.OnboardingPage.next
            default:
                return Texts.OnboardingPage.forbidden
            }
            
        case .getLocationPermission(let access):
            switch access {
            case .notDetermined:
                return Texts.OnboardingPage.permission
            case .authorizedAlways, .authorizedWhenInUse:
                return Texts.OnboardingPage.begin
            default:
                return Texts.OnboardingPage.forbidden
            }
        }
    }
    
    internal var showSkipButton: Bool {
        switch self {
        case .nextPage:
            return false
        case .getMicrophonePermission:
            return true
        case .getLocationPermission:
            return true
        }
    }
    
    static func == (lhs: OnboardingButtonType, rhs: OnboardingButtonType) -> Bool {
        return lhs.title == rhs.title
    }
}

