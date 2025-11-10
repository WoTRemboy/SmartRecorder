//
//  OnboardingViewModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 08/11/2025.
//

import Foundation
import SwiftUI
import Combine

final class OnboardingViewModel: ObservableObject {
    
    @AppStorage(Texts.UserDefaults.skipOnboarding) var skipOnboarding: Bool = false
    @Published internal var steps = OnboardingStep.stepsSetup()
    @Published internal var currentStep = 0
    
    // MARK: - Computed Properties
    
    /// Pages for the onboarding process.
    internal var pages: [Int] {
        Array(0..<steps.count)
    }
    
    internal var buttonType: OnboardingButtonType {
        if currentStep < steps.count - 2 {
            return .nextPage
        } else if currentStep == steps.count - 2 {
            return .getMicrophonePermission
        } else {
            return .getLocationPermission
        }
    }
    
    internal func setupCurrentStep(newValue: Int) {
        currentStep = newValue
    }
    
    internal func transferToMainPage() {
        skipOnboarding.toggle()
    }
    
    /// Draws the "drawOn" symbol effect asynchronously for the given page index.
    internal func drawOnSymbol(_ index: Int) async {
        try? await Task.sleep(for: .seconds(0.5))
        steps[index].drawOn = true
    }
    
    /// Starts a new asynchronous task to trigger the drawOnSymbol function.
    /// This allows async invocation from synchronous contexts such as onChange handlers.
    internal func triggerDrawOnSymbol(_ index: Int) {
        Task {
            await drawOnSymbol(index)
        }
    }
}
