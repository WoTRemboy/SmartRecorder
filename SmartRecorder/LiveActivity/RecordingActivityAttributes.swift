// RecordingActivityAttributes.swift
// SmartRecorder
//
// Shared between the main app target and the Widget Extension target.
// Add this file to BOTH targets in Xcode (target membership).

import ActivityKit
import Foundation

struct RecordingActivityAttributes: ActivityAttributes {

    // MARK: - Recording Status

    enum RecordingStatus: String, Codable, Hashable {
        case recording      // Идёт активная запись
        case paused         // Пользователь поставил на паузу
        case processing     // Первичная обработка аудио
        case uploading      // Загрузка на сервер
        case transcribing   // Расшифровка речи в текст
    }

    // MARK: - Dynamic State (updates during the activity)

    struct ContentState: Codable, Hashable {
        var recordingStatus: RecordingStatus
        var participantCount: Int
    }

    // MARK: - Static Data (set once at start, never changes)

    var locationName: String?       // street / place name
    var cityName: String?           // city
    var recordingStartDate: Date    // used for elapsed-time timer
}
