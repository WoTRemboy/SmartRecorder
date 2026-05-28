// RecordingLiveActivityWidget.swift
// RecordingLiveActivityExtension
//
// This file belongs to the Widget Extension target.
// RecordingActivityAttributes.swift must also be added to this target.

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Status display helpers (widget-side only)

private extension RecordingActivityAttributes.RecordingStatus {
    var label: String {
        switch self {
        case .recording:    return "Идёт запись"
        case .paused:       return "Запись на паузе"
        case .processing:   return "Обработка..."
        case .uploading:    return "Загрузка на сервер"
        case .transcribing: return "Расшифровка речи"
        }
    }

    var systemImage: String {
        switch self {
        case .recording:    return "record.circle.fill"
        case .paused:       return "pause.circle.fill"
        case .processing:   return "gearshape.fill"
        case .uploading:    return "arrow.up.circle.fill"
        case .transcribing: return "text.bubble.fill"
        }
    }

    var color: Color {
        switch self {
        case .recording:    return .red
        case .paused:       return .yellow
        case .processing:   return Color(red: 0.2, green: 0.5, blue: 1.0)
        case .uploading:    return Color(red: 0.2, green: 0.5, blue: 1.0)
        case .transcribing: return .purple
        }
    }
}

// MARK: - Lock Screen / Notification Center view

struct RecordingLockScreenView: View {
    let attributes: RecordingActivityAttributes
    let state: RecordingActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            iconView
            infoColumn
            Spacer(minLength: 0)
            timerColumn
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // Pulsing mic icon in a tinted circle
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(state.recordingStatus.color.opacity(0.18))
                .frame(width: 50, height: 50)
            Image(systemName: "mic.fill")
                .font(.title2)
                .foregroundStyle(state.recordingStatus.color)
                .symbolEffect(
                    .pulse,
                    options: .repeating,
                    isActive: state.recordingStatus == .recording
                )
        }
    }

    // Left column: title, status, location
    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Запись встречи")
                .font(.headline)
                .foregroundStyle(.primary)

            Label(state.recordingStatus.label, systemImage: state.recordingStatus.systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(state.recordingStatus.color)

            if let location = locationText {
                Label(location, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // Right column: elapsed timer + participant count
    private var timerColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(attributes.recordingStartDate, style: .timer)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 88, alignment: .trailing)

            Label("\(state.participantCount)", systemImage: "person.2.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .trailing)
        }
    }

    private var locationText: String? {
        [attributes.locationName, attributes.cityName]
            .compactMap { $0 }
            .first   // space-limited: show the most specific part
    }
}

// MARK: - Widget Entry Point

@main
struct RecordingLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            // Lock Screen & Notification Center
            RecordingLockScreenView(
                attributes: context.attributes,
                state: context.state
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .foregroundStyle(context.state.recordingStatus.color)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.recordingStartDate, style: .timer)
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(width: 62, alignment: .trailing)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.recordingStatus.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(context.state.recordingStatus.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        if let loc = context.attributes.locationName {
                            Label(loc, systemImage: "location.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Label(
                            "\(context.state.participantCount) уч.",
                            systemImage: "person.2.fill"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: 220)
                    .padding(.bottom, 4)
                }

            } compactLeading: {
                Image(systemName: "mic.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(context.state.recordingStatus.color)
                    .symbolEffect(
                        .pulse,
                        options: .repeating,
                        isActive: context.state.recordingStatus == .recording
                    )

            } compactTrailing: {
                Text(context.attributes.recordingStartDate, style: .timer)
                    .monospacedDigit()
                    .font(.caption2.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 42, alignment: .trailing)

            } minimal: {
                Image(systemName: "mic.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(context.state.recordingStatus.color)
            }
            .widgetURL(URL(string: "smartrecorder://recording"))
            .keylineTint(context.state.recordingStatus.color)
        }
    }
}
