//
//  RecordsModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 05/12/2025.
//

import Foundation
import Combine

struct RecordResponse: Codable {
    let id: Int64
    let folderId: Int64?
    let title: String?
    let description: String?
    let summary: RecordSummaryResponse?
    let statuses: [ProcessingStatusResponse]
    let datetime: Date?
    let latitude: Double?
    let longitude: Double?
    let duration: Int64?
    let category: String?
    let audioUrl: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case folderId
        case title
        case description
        case summary
        case statuses
        case datetime
        case latitude
        case longitude
        case duration
        case category
        case audioUrl
        case createdAt
        case updatedAt
    }
}

extension RecordResponse {
    private static let serverDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }()

    private static let createdAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        folderId = try container.decodeIfPresent(Int64.self, forKey: .folderId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        summary = try container.decodeIfPresent(RecordSummaryResponse.self, forKey: .summary)
        statuses = try container.decodeIfPresent([ProcessingStatusResponse].self, forKey: .statuses) ?? []
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        duration = try container.decodeIfPresent(Int64.self, forKey: .duration)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)

        if let datetimeString = try container.decodeIfPresent(String.self, forKey: .datetime) {
            datetime = RecordResponse.date(from: datetimeString)
        } else {
            datetime = nil
        }

        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = RecordResponse.date(from: createdAtString)
        } else {
            createdAt = nil
        }

        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = RecordResponse.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }

    private static func date(from value: String) -> Date? {
        if let date = createdAtFormatter.date(from: value) {
            return date
        }
        if let date = serverDateFormatter.date(from: value) {
            return date
        }
        return ISO8601DateFormatter().date(from: value)
    }
}

struct RecordsPage: Codable {
    let content: [RecordResponse]
    let totalElements: Int
    let totalPages: Int
}

struct RecordSummaryResponse: Codable, Hashable {
    let summaryText: String
    let modelUsed: String?
    let createdAt: String?
}

struct ProcessingStatusResponse: Codable, Hashable {
    let stage: ProcessingStage
    let status: ProcessingStatus
    let errorMessage: String?
    let updatedAt: String?
}

enum ProcessingStage: String, Codable, Hashable {
    case transcription
    case summarization
}

enum ProcessingStatus: String, Codable, Hashable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
}

enum RecordAccessRole: String, Codable, Hashable, CaseIterable {
    case owner
    case editor
    case viewer

    var title: String {
        switch self {
        case .owner:
            return "Владелец"
        case .editor:
            return "Редактор"
        case .viewer:
            return "Просмотр"
        }
    }
}

struct SharedRecordUserResponse: Codable, Identifiable, Hashable {
    var id: String { userId }

    let userId: String
    let email: String
    let fullName: String?
    let role: RecordAccessRole
}

struct SharedRecordResponse: Codable {
    let record: RecordResponse
    let role: RecordAccessRole
    let sharedByUserId: String?
    let sharedAt: String?
}
