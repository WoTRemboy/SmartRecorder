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
import AVFoundation
import CoreData
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SmartRecorder", category: "RecorderViewModel")

@MainActor
final class RecorderViewModel: ObservableObject {
    
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var showTimerView: Bool = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var isStartingRecording: Bool = false

    @Published internal var participantCount: Int = 1

    @Published private(set) var microphone: AVAudioSessionPortDescription? = nil
    @Published private(set) var availableMicrophones: [AVAudioSessionPortDescription?] = []
    
    @Published internal var streetName: String? = nil
    @Published internal var cityName: String? = nil
    @Published private(set) var locationPermissionDenied: Bool = false

    @Published internal var saveNoteTitle: String = ""
    @Published private(set) var saveNoteFolder: NoteFolder = .work

    @Published internal var showLocationPermissionAlert: Bool = false
    @Published internal var showSaveSheetView: Bool = false
    @Published internal var showSaveSuccessAlert: Bool = false
    @Published internal var showSaveErrorAlert: Bool = false

    @Published var amplitudes: [Float] = Array(repeating: 0, count: 16)
    @Published private(set) var liveTranscription: String = ""
    @Published private(set) var isTranscribing: Bool = false
    @Published var isLiveTranscriptionExpanded: Bool = false

    private let locationService = LocationService.shared
    
    private var timerTask: Task<Void, Never>? = nil
    private var recordTimerCancellable: AnyCancellable?
    private var authorizationCancellable: AnyCancellable?
    
    private var audioRecorderService: AudioRecorderService?
    private var amplitudeCancellable: AnyCancellable?
    private var transcriptionCancellable: AnyCancellable?
    private var transcriptionStateCancellable: AnyCancellable?

    internal var timerString: String {
        String(format: "%02d:%02d", Int(elapsedTime) / 60, Int(elapsedTime) % 60)
    }
    
    init() {
        prepareAudioSessionData()
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

    internal func incrementParticipants() {
        participantCount = min(participantCount + 1, 99)
        if isRecording {
            Task { await LiveActivityService.shared.updateActivity(
                status: .recording,
                participantCount: participantCount
            )}
        }
    }

    internal func decrementParticipants() {
        participantCount = max(participantCount - 1, 1)
        if isRecording {
            Task { await LiveActivityService.shared.updateActivity(
                status: .recording,
                participantCount: participantCount
            )}
        }
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
                logger.error("Failed to get current location: \(String(describing: error))")
                self.locationPermissionDenied = true
                return
            }
        }
        do {
            let names = try await locationService.reverseGeocode(location: location)
            self.streetName = names.street
            self.cityName = names.city
        } catch {
            logger.error("Reverse geocoding failed: \(String(describing: error))")
            self.streetName = nil
            self.cityName = nil
        }
    }
    
    // MARK: - Audio helpers
    
    private func prepareAudioSessionData() {
        let service = AudioRecorderService()
        audioRecorderService = service
        
        do {
            try service.prepareAudioSession()
            refreshAvailableMicrophones()
        }
        catch {
            logger.info("Failed to start audio session: \(error)")
        }
        
    }
    
    private func audioDuration(for fileURL: URL) async -> TimeInterval? {
        let asset = AVURLAsset(url: fileURL)
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return seconds.isFinite ? seconds : nil
        } catch {
            return nil
        }
    }
    
    private func integerSeconds(from seconds: TimeInterval?) -> Int? {
        guard let s = seconds, s.isFinite else { return nil }
        return Int(s.rounded())
    }
    
    internal func changeMicrophone(_ device: AVAudioSessionPortDescription) {
        do {
            if let selectedDevice = try audioRecorderService?.chooseMicrophone(microphone: device) {
                microphone = selectedDevice
                refreshAvailableMicrophones()
            }
        }
        catch {
            logger.info("Failed to choose microphone: \(error)")
        }
    }

    private func refreshAvailableMicrophones() {
        guard let audioRecorderService else {
            availableMicrophones = []
            microphone = nil
            return
        }

        let microphones = audioRecorderService.getMicrophones()
        availableMicrophones = microphones

        if let selected = microphone,
           let refreshedSelection = microphones.first(where: { $0.uid == selected.uid }) {
            microphone = refreshedSelection
        } else {
            microphone = audioRecorderService.selectedMicrophone()
        }
    }
    
    internal func toggleRecording() {
        guard !isStartingRecording else { return }

        if isRecording {
            stopRecordingSession()
        } else {
            Task {
                await startRecordingSession()
            }
        }
    }

    private func startRecordingSession() async {
        logger.info("Recording start requested")
        isStartingRecording = true
        resetRecordingUI()

        let service = AudioRecorderService()
        audioRecorderService = service
        amplitudeCancellable?.cancel()
        amplitudeCancellable = service.$amplitudes
            .receive(on: RunLoop.main)
            .sink { [weak self] amps in
                self?.amplitudes = amps
            }

        do {
            try await service.startRecording()
            isRecording = true
            isStartingRecording = false
            startRecordingTimers()
            LiveActivityService.shared.startActivity(
                locationName: streetName,
                cityName: cityName,
                participantCount: participantCount
            )
        } catch {
            logger.error("Failed to start recording: \(String(describing: error))")
            isRecording = false
            isStartingRecording = false
            audioRecorderService = nil
            amplitudeCancellable?.cancel()
            amplitudeCancellable = nil
            amplitudes = Array(repeating: 0, count: 16)
            showTimerView = false
            await LiveActivityService.shared.endImmediately()
        }
    }

    private func stopRecordingSession() {
        isRecording = false
        logger.info("Recording stop requested. elapsedTime=\(self.elapsedTime)")
        stopRecordingTimers()
        amplitudeCancellable?.cancel()

        guard let service = audioRecorderService else { return }
        Task {
            LoadingOverlay.shared.show()
            await service.stopRecording()
            await LiveActivityService.shared.stopActivity()
            LoadingOverlay.shared.hide()
            showSaveSheetView.toggle()
        }
    }

    private func resetRecordingUI() {
        isRecording = false
        showTimerView = false
        elapsedTime = 0
        stopRecordingTimers()
    }

    private func startRecordingTimers() {
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
            isRecording = false
            logger.info("Recording stop requested. elapsedTime=\(self.elapsedTime)")
            isLiveTranscriptionExpanded = false
            showTimerView = false
            timerTask?.cancel()
            timerTask = nil
            recordTimerCancellable?.cancel()
            if let service = audioRecorderService {
                Task {
                    LoadingOverlay.shared.show()
                    await service.stopRecording()
                    self.liveTranscription = service.transcriptionText
                    self.isTranscribing = false
                    LoadingOverlay.shared.hide()
                    showSaveSheetView.toggle()
                }
            }
            amplitudeCancellable?.cancel()
            transcriptionCancellable?.cancel()
            transcriptionStateCancellable?.cancel()
        } else {
            guard let service = audioRecorderService else {
                logger.error("Recording start failed: audio recorder service is missing")
                isRecording = false
                return
            }

            refreshAvailableMicrophones()
            isRecording = true
            logger.info("Recording start requested")
            isLiveTranscriptionExpanded = false
            showTimerView = false
            elapsedTime = 0
            liveTranscription = ""
            isTranscribing = false
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
            
            Task {
                do {
                    try await service.startRecording()
                } catch {
                    await MainActor.run {
                        self.isRecording = false
                        self.showTimerView = false
                        self.recordTimerCancellable?.cancel()
                        self.timerTask?.cancel()
                    }
                }
            }
            amplitudeCancellable = service.$amplitudes
                .receive(on: RunLoop.main)
                .sink { [weak self] amps in
                    self?.amplitudes = amps
                }
            transcriptionCancellable = service.$transcriptionText
                .receive(on: RunLoop.main)
                .sink { [weak self] text in
                    self?.liveTranscription = text
                }
            transcriptionStateCancellable = service.$isTranscribing
                .receive(on: RunLoop.main)
                .sink { [weak self] isTranscribing in
                    self?.isTranscribing = isTranscribing
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

    private func stopRecordingTimers() {
        showTimerView = false
        timerTask?.cancel()
        timerTask = nil
        recordTimerCancellable?.cancel()
        recordTimerCancellable = nil
    }

    internal func setLiveTranscriptionExpanded(_ isExpanded: Bool) {
        isLiveTranscriptionExpanded = isExpanded
    }
    
    @MainActor
    func saveCurrentNote() async {
        let title = saveNoteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let folderId = saveNoteFolder.rawValue

        let fileName = audioRecorderService?.recordedFileName()
        let now = Date()
        let locationObj = locationService.lastKnownLocation

        let fileURL: URL? = AudioRecorderService.url(forFileName: fileName)
        var fileDuration: TimeInterval? = nil
        if let url = fileURL {
            fileDuration = await audioDuration(for: url)
        }
        let durationToSave: Int? = {
            if let s = fileDuration, s.isFinite { return Int(s.rounded()) }
            if elapsedTime > 0 { return Int(elapsedTime.rounded()) }
            return nil
        }()
        
        let noteLocation: Location? = {
            guard let loc = locationObj else { return nil }
            return Location(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                cityName: cityName,
                streetName: streetName
            )
        }()
        let noteId = UUID()
        let note = Note(
            id: noteId,
            serverId: nil,
            folderId: folderId,
            title: title,
            transcription: liveTranscription.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            audioPath: fileName,
            createdAt: now,
            updatedAt: now,
            duration: durationToSave,
            location: noteLocation
        )
        
        let noteService = NoteEntityService.shared
        do {
            _ = try await noteService.create(note)
            logger.info("Note saved locally. title=\(title), duration=\(durationToSave ?? -1)")
            // Fire-and-forget upload to server after local save
            if let fileURL = fileURL {
                let place: String? = {
                    if let loc = locationObj {
                        return "\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
                    }
                    return nil
                }()
                Task.detached { [noteId, title, now, folderId, place, fileURL] in
                    do {
                        let response = try await RecordsService.shared.uploadRecord(
                            fileURL: fileURL,
                            name: title,
                            datetime: now,
                            category: folderId,
                            folderId: 1,
                            place: place
                        )
                        let serverId = String(response.id)
                        if var updatedNote = try await noteService.fetch(NoteFetchOptions(query: NoteQuery(), limit: 0)).first(where: { $0.id == noteId }) {
                            updatedNote.serverId = serverId
                            _ = try await noteService.upsert(updatedNote)
                        }
                        
                        await Toast.shared.present(title: Texts.RecorderPage.Toasts.uploadSuccess)
                    } catch {
                        await Toast.shared.present(title: Texts.RecorderPage.Toasts.uploadFailed)
                        await logger.error("Upload record failed: \(String(describing: error))")
                    }
                }
            }
            showSaveSheetView.toggle()
            showSaveSuccessAlert.toggle()
        } catch {
            logger.error("Failed to save note: \(String(describing: error))")
            showSaveSheetView.toggle()
            showSaveErrorAlert.toggle()
        }
        saveNoteTitle = ""
    }
    
    deinit {
        timerTask?.cancel()
        recordTimerCancellable?.cancel()
        authorizationCancellable?.cancel()
        amplitudeCancellable?.cancel()
        transcriptionCancellable?.cancel()
        transcriptionStateCancellable?.cancel()
        if let audioRecorderService = audioRecorderService {
            Task { @MainActor in
                await audioRecorderService.stopRecording()
            }
        }
    }
    
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
