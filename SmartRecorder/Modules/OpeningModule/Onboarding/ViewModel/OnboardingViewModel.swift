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
import AVFoundation

final class OnboardingViewModel: ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    
    @AppStorage(Texts.UserDefaults.skipOnboarding) var skipOnboarding: Bool = false
    @Published internal var steps = OnboardingStep.stepsSetup()
    @Published internal var currentStep = 0
    @Published internal var locationAuthorizationStatus: CLAuthorizationStatus = LocationService.shared.authorizationStatus
    
    @Published internal var showLocationPermissionAlert: Bool = false
    @Published internal var microphoneGranted: Bool = (AVAudioApplication.shared.recordPermission == .granted)
    @Published internal var showMicrophonePermissionAlert: Bool = false
    
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
        
        Task { @MainActor in
            let perm = AVAudioApplication.shared.recordPermission
            self.microphoneGranted = (perm == .granted)
            if self.steps.indices.contains(2) {
                withAnimation {
                    self.steps[2].grantedAccess = self.microphoneGranted
                }
            }
        }
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
            return .getMicrophonePermission(access: AVAudioApplication.shared.recordPermission)
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
        case .nextPage:
            withAnimation { externalAction() }
        case .getMicrophonePermission:
            let perm = AVAudioApplication.shared.recordPermission
            switch perm {
            case .granted:
                withAnimation { externalAction() }
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        withAnimation {
                            self.microphoneGranted = allowed
                        }
                        if self.steps.indices.contains(2) {
                            withAnimation {
                                self.steps[2].grantedAccess = allowed
                            }
                        }
                    }
                }
            case .denied:
                showMicrophonePermissionAlert.toggle()
            @unknown default:
                showMicrophonePermissionAlert.toggle()
            }
        case .getLocationPermission(let access):
            switch access {
            case .authorizedAlways, .authorizedWhenInUse:
                withAnimation { self.transferToMainPage() }
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
            withAnimation { self.transferToMainPage() }
        case .getMicrophonePermission:
            withAnimation { externalAction() }
        default:
            withAnimation { externalAction() }
        }
    }
}

