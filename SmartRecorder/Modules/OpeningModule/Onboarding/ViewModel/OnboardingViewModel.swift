//
//  OnboardingViewModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 08/11/2025.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

final class OnboardingViewModel: ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    
    @AppStorage(Texts.UserDefaults.skipOnboarding) var skipOnboarding: Bool = false
    @Published internal var steps = OnboardingStep.stepsSetup()
    @Published internal var currentStep = 0
    @Published internal var locationAuthorizationStatus: CLAuthorizationStatus = LocationService.shared.authorizationStatus
    
    @Published internal var showLocationPermissionAlert: Bool = false
    
    init() {
        LocationService.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \OnboardingViewModel.locationAuthorizationStatus, on: self)
            .store(in: &cancellables)
        
        LocationService.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self, self.steps.indices.contains(3) else { return }
                withAnimation {
                    self.steps[3].grantedAccess = (status == .authorizedAlways || status == .authorizedWhenInUse)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    /// Pages for the onboarding process.
    internal var pages: [Int] {
        Array(0..<steps.count)
    }
    
    internal var isLastPage: Bool {
        currentStep == steps.count - 1
    }
    
    internal var buttonType: OnboardingButtonType {
        if currentStep < steps.count - 2 {
            return .nextPage
        } else if currentStep == steps.count - 2 {
            return .getMicrophonePermission
        } else {
            return .getLocationPermission(access: locationAuthorizationStatus)
        }
    }
    
    internal var showSkipButton: Bool {
        currentStep >= steps.count - 2 && !steps[currentStep].grantedAccess
    }
    
    internal func setupCurrentStep(newValue: Int) {
        currentStep = newValue
    }
    
    internal func transferToMainPage() {
        skipOnboarding.toggle()
    }
    
    /// Draws the "drawOn" symbol effect asynchronously for the given page index.
    internal func drawOnSymbol(_ index: Int) async {
        try? await Task.sleep(for: .seconds(0.2))
        steps[index].drawOn = true
    }
    
    /// Starts a new asynchronous task to trigger the drawOnSymbol function.
    internal func triggerDrawOnSymbol(_ index: Int) {
        Task {
            await drawOnSymbol(index)
        }
    }
    
    internal func handleActionButtonTap(externalAction: @escaping () -> Void) {
        switch buttonType {
        case .nextPage, .getMicrophonePermission:
            withAnimation {
                externalAction()
            }
        case .getLocationPermission(let access):
            switch access {
            case .authorizedAlways, .authorizedWhenInUse:
                withAnimation {
                    self.transferToMainPage()
                }
            case .notDetermined:
                LocationService.shared.requestAuthorization()
            default:
                showLocationPermissionAlert.toggle()
            }
        }
    }
    
    internal func handleSkipButtonTap(externalAction: @escaping () -> Void) {
        switch buttonType {
        case .getLocationPermission(_):
            withAnimation {
                self.transferToMainPage()
            }
        default:
            withAnimation {
                externalAction()
            }
        }
    }
}
