// LiveActivityService.swift
// SmartRecorder

import ActivityKit
import Foundation
import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "SmartRecorder",
    category: "LiveActivityService"
)

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var activity: Activity<RecordingActivityAttributes>?

    private init() {}

    // MARK: - Public API

    func startActivity(locationName: String?, cityName: String?, participantCount: Int) {
        if activeActivity() != nil {
            logger.info("Live Activity is already active")
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.info("Live Activities are disabled on this device")
            return
        }

        let attributes = RecordingActivityAttributes(
            locationName: locationName,
            cityName: cityName,
            recordingStartDate: Date()
        )
        let state = RecordingActivityAttributes.ContentState(
            recordingStatus: .recording,
            participantCount: participantCount
        )
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            activity = try Activity<RecordingActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            logger.info("Live Activity started (id=\(self.activity?.id ?? "?"))")
        } catch {
            logger.error("Failed to start Live Activity: \(String(describing: error))")
        }
    }

    func updateActivity(
        status: RecordingActivityAttributes.RecordingStatus,
        participantCount: Int
    ) async {
        guard let activity = activeActivity() else { return }
        let state = RecordingActivityAttributes.ContentState(
            recordingStatus: status,
            participantCount: participantCount
        )
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
    }

    func stopActivity() async {
        guard let activity = activeActivity() else { return }
        // Show "Processing" state briefly before dismissal
        let finalState = RecordingActivityAttributes.ContentState(
            recordingStatus: .processing,
            participantCount: activity.content.state.participantCount
        )
        let finalContent = ActivityContent(
            state: finalState,
            staleDate: Date().addingTimeInterval(5)
        )
        await activity.end(finalContent, dismissalPolicy: .after(.now + 4))
        self.activity = nil
        logger.info("Live Activity ended")
    }

    func endImmediately() async {
        guard let activity = activeActivity() else { return }
        let content = ActivityContent(
            state: activity.content.state,
            staleDate: Date()
        )
        await activity.end(content, dismissalPolicy: .immediate)
        self.activity = nil
    }

    private func activeActivity() -> Activity<RecordingActivityAttributes>? {
        if let activity {
            return activity
        }

        activity = Activity<RecordingActivityAttributes>.activities.first
        return activity
    }
}
