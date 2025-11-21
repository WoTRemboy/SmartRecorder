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
import AVFoundation
import CoreData

@MainActor
final class RecorderViewModel: ObservableObject {
    
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var showTimerView: Bool = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    
    @Published private(set) var streetName: String? = nil
    @Published private(set) var cityName: String? = nil
    @Published private(set) var locationPermissionDenied: Bool = false
    
    @Published internal var saveNoteTitle: String = ""
    @Published private(set) var saveNoteFolder: NoteFolder = .work
    
    @Published internal var showLocationPermissionAlert: Bool = false
    @Published internal var showSaveSheetView: Bool = false
    @Published internal var showSaveSuccessAlert: Bool = false
    @Published internal var showSaveErrorAlert: Bool = false
    
    @Published var amplitudes: [Float] = Array(repeating: 0, count: 16)

    private let locationService = LocationService.shared
    
    private var timerTask: Task<Void, Never>? = nil
    private var recordTimerCancellable: AnyCancellable?
    private var authorizationCancellable: AnyCancellable?
    
    private var audioRecorderService: AudioRecorderService?
    private var amplitudeCancellable: AnyCancellable?

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
    
    internal func isSelectedFolder(_ folder: NoteFolder) -> Bool {
        saveNoteFolder == folder
    }
    
    internal func setSaveFolder(_ folder: NoteFolder) {
        saveNoteFolder = folder
    }
    
    internal func toggleShowSaveSheetView() {
        showSaveSheetView.toggle()
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
                if let cityName = mapItems.first?.addressRepresentations?.cityName {
                    self.cityName = cityName
                } else {
                    self.cityName = nil
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
            if let service = audioRecorderService {
                Task {
                    await service.stopRecording()
                    showSaveSheetView.toggle()
                }
            }
            amplitudeCancellable?.cancel()
            audioRecorderService = nil
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
            
            let service = AudioRecorderService()
            audioRecorderService = service
            Task {
                try? await service.startRecording()
            }
            amplitudeCancellable = service.$amplitudes
                .receive(on: RunLoop.main)
                .sink { [weak self] amps in
                    self?.amplitudes = amps
                }
        }
    }
    
    @MainActor
    func saveCurrentNote() async {
        let title = saveNoteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let folderId = saveNoteFolder.rawValue
        let filePath = audioRecorderService?.recordedFileURL()?.path
        let now = Date()
        let locationObj = locationService.lastKnownLocation
        let noteLocation: Location? = {
            guard let loc = locationObj else { return nil }
            return Location(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                cityName: cityName,
                streetName: streetName
            )
        }()
        let note = Note(
            id: UUID(),
            serverId: nil,
            folderId: folderId,
            title: title,
            transcription: nil,
            audioPath: filePath,
            createdAt: now,
            updatedAt: now,
            location: noteLocation
        )
        let noteService = NoteEntityService()
        do {
            _ = try await noteService.create(note)
            showSaveSheetView.toggle()
            showSaveSuccessAlert.toggle()
        } catch {
            print("Failed to save note: \(error)")
            showSaveSheetView.toggle()
            showSaveErrorAlert.toggle()
        }
        saveNoteTitle = ""
        saveNoteFolder = .work
    }
    
    deinit {
        timerTask?.cancel()
        recordTimerCancellable?.cancel()
        authorizationCancellable?.cancel()
        amplitudeCancellable?.cancel()
        if let audioRecorderService = audioRecorderService {
            Task { @MainActor in
                await audioRecorderService.stopRecording()
            }
        }
    }
    
}
