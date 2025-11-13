//
//  RecorderViewModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 13/11/2025.
//

import Foundation
import Combine
import SwiftUI
import CoreLocation
import MapKit

@MainActor
final class RecorderViewModel: ObservableObject {
    
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var showTimerView: Bool = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    
    @Published private(set) var streetName: String? = nil
    @Published private(set) var locationPermissionDenied: Bool = false
    
    @Published internal var showLocationPermissionAlert: Bool = false

    private let locationService = LocationService.shared
    
    private var timerTask: Task<Void, Never>? = nil
    private var recordTimerCancellable: AnyCancellable?
    private var authorizationCancellable: AnyCancellable?
    
    internal var timerString: String {
        String(format: "%02d:%02d", Int(elapsedTime) / 60, Int(elapsedTime) % 60)
    }
    
    init() {
        authorizationCancellable = locationService.$authorizationStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .authorizedAlways || status == .authorizedWhenInUse {
                    Task {
                        await self.ensureLocation()
                    }
                }
            }
    }
    
    internal func toggleShowLocationPermissionAlert() {
        if !locationService.grantedAccess {
            showLocationPermissionAlert.toggle()
        }
    }
    
    internal func ensureLocation() async {
        if !locationService.grantedAccess {
            locationService.requestAuthorization()
            return
        }
        let location: CLLocation
        if let last = locationService.lastKnownLocation {
            location = last
        } else {
            do {
                location = try await locationService.requestCurrentLocation()
            } catch {
                self.locationPermissionDenied = true
                return
            }
        }
        updateStreetName(from: location)
    }
    
    private func updateStreetName(from location: CLLocation) {
        guard let request = MKReverseGeocodingRequest(location: location) else { return }
        Task {
            do {
                let mapItems = try await request.mapItems
                if let address = mapItems.first?.name {
                    self.streetName = address
                } else {
                    self.streetName = nil
                }
            } catch {
                self.streetName = nil
            }
        }
    }
    
    internal func toggleRecording() {
        if isRecording {
            isRecording = false
            showTimerView = false
            timerTask?.cancel()
            timerTask = nil
            recordTimerCancellable?.cancel()
        } else {
            isRecording = true
            showTimerView = false
            elapsedTime = 0
            timerTask?.cancel()
            timerTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    if self?.isRecording == true {
                        withAnimation {
                            self?.showTimerView = true
                        }
                    }
                }
            }
            recordTimerCancellable?.cancel()
            recordTimerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self, self.isRecording else { return }
                    self.elapsedTime += 1
                }
        }
    }
    
    deinit {
        timerTask?.cancel()
        recordTimerCancellable?.cancel()
        authorizationCancellable?.cancel()
    }
    
}
