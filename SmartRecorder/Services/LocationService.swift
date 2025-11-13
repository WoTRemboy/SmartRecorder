//
//  LocationService.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 11.11.2025.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    enum LocationError: Error, LocalizedError {
        case restricted
        case denied
        case unableToFetch
        case unknown
        case notDetermined

        var errorDescription: String? {
            switch self {
            case .restricted:
                return "Location access is restricted."
            case .denied:
                return "Location access was denied by the user."
            case .unableToFetch:
                return "Failed to obtain coordinates."
            case .unknown:
                return "Unknown location error."
            case .notDetermined:
                return "Authorization has not been requested."
            }
        }
    }

    /// The current authorization status.
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// The last known user location.
    @Published private(set) var lastKnownLocation: CLLocation?
    /// The last location error encountered.
    @Published private(set) var locationError: LocationError?

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    internal var grantedAccess: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = locationManager.authorizationStatus
    }

    /// Requests "When In Use" location authorization from the user.
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Asynchronously requests the current user location once.
    ///
    /// - Throws: `LocationError` if location cannot be accessed or authorization is denied.
    /// - Returns: The current `CLLocation` of the user.
    func requestCurrentLocation() async throws -> CLLocation {
        let status = locationManager.authorizationStatus
        if status == .restricted { throw LocationError.restricted }
        if status == .denied { throw LocationError.denied }
        if status == .notDetermined {
            throw LocationError.notDetermined
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .denied {
            locationError = .denied
        } else if authorizationStatus == .restricted {
            locationError = .restricted
        } else {
            locationError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            self.locationError = .unableToFetch
            locationContinuation?.resume(throwing: LocationError.unableToFetch)
            locationContinuation = nil
            return
        }
        self.lastKnownLocation = location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationError = .unknown
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}
